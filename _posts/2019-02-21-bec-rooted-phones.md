---
layout: post
author: eyJhb
title:  "Bypassing BECs Security Measures for Android"
date:   2019-02-21 18:00:00 +0000
categories: reverse-engineering
---
Recently my bank started blocking users, who has rooted their Android phones from using their banking app.
This was of great annoyance to start with, but I quickly just found a older version of the app without this limitation.
This worked great for a number of months, but last week they disabled access for old versions of their app and I could not use the banking app any more.

My initial thought was just to decompile the old version I had of the app, change the version number, recompile and jackpot!

I did this using my Docker Image [Android-re](https://hub.docker.com/r/eyjhb/android-re), which has the basic tools for reverse engineering Android applications.
First get a copy of the Android application you want to reverse (in my case I just searched Google for the version), and then fire up the Docker container!

```
docker run --rm -it --privileged \
    -v $(pwd):/src
    eyjhb:android-re
    bash
```

Then decompile the `apk` using `apktool d base.apk`, which will create a directory called `base/` where `apktool.yml` is located.
Inside this file the version strings are located, which can easily be changed.

```
versionCode: '300080078'
versionName: 3.0.8-78
----
versionCode: '400080019'
versionName: 4.0.8-19
```

Then recompile it again using `apktool b base`, which will create the file `base/dists/base.apk`.
This then needs to be signed using `jarsigner` and `zipalign`. 
A example of this can be seen [here](https://github.com/eyJhb/docker-images/blob/master/tools/android-re/scripts/sign.sh), or for the lazy person using my Docker Image just run `sign.sh base/dists/base.apk` which will create the file `base-aligned.apk` which is then ready to be installed! 

But this was not the case, as I quickly found out that as soon as you recompile the app, it will no longer be allowed to communicate with BECs servers.
Digging around on the internet, I found [this](https://www.airpair.com/android/posts/adding-tampering-detection-to-your-android-app) website which described a method for detecting tampering, by getting the `signatures` used to sign the app.
This is a easy method of validating whether or not the app has been tampered with, and sure enough searching for `signatures` revealed the code responsible for invalidating my tampered app.

   
```
# smali/dk/bec/android/mb1/dao/MobileBankSecureContext.smali
.method protected getOwnBytes()[B
    .locals 14

    .prologue
    .line 198
    const/4 v2, 0x0

    .line 200
    .local v2, "mReturn":[B
    :try_start_0
    iget-object v8, p0, Ldk/bec/android/mb1/dao/MobileBankSecureContext;->context:Landroid/content/Context;

    invoke-virtual {v8}, Landroid/content/Context;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v8

    iget-object v9, p0, Ldk/bec/android/mb1/dao/MobileBankSecureContext;->context:Landroid/content/Context;

    invoke-virtual {v9}, Landroid/content/Context;->getPackageName()Ljava/lang/String;

    move-result-object v9

    const/16 v10, 0x40

    invoke-virtual {v8, v9, v10}, Landroid/content/pm/PackageManager;->getPackageInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;

    move-result-object v8

    iget-object v6, v8, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    .line 201
    .local v6, "signatures":[Landroid/content/pm/Signature;
    array-length v9, v6
<snipped>
```

The above code is a method called `getOwnBytes`, which uses the `signatures` to calculate a bytes objects (it has multiple methods of fingerprinting), which is then
used by the function `calculateKey`.
This function is used to calculate the public certificate key, that the client will use to communicate with the server.
Thereby if the app has been tampered with, the `getOwnBytes` function will return a different byte array, and the `calculateKey` will return the wrong public key.
This will in turn tell the server, that it should not communicate with our app.

```
# smali/dk/bec/android/mb1/dao/MobileBankSecureContext.smali
.method private calculateKey(Ljava/lang/String;)Ljava/security/PublicKey;
    .locals 6
    .param p1, "key"    # Ljava/lang/String;

    .prologue
    .line 182
    invoke-virtual {p0}, Ldk/bec/android/mb1/dao/MobileBankSecureContext;->getOwnBytes()[B

    move-result-object v3

    .line 183
    .local v3, "mPackageBytes":[B
    invoke-static {p1}, Lorg/apache/commons/codec/binary/StringUtils;->getBytesUtf8(Ljava/lang/String;)[B

    move-result-object v5

    invoke-static {v5}, Lorg/apache/commons/codec/binary/Base64;->decodeBase64([B)[B

    move-result-object v5

    invoke-virtual {p0, v5, v3}, Ldk/bec/android/mb1/dao/MobileBankSecureContext;->blend([B[B)[B

    move-result-object v2

    .line 186
    .local v2, "mNewBytes":[B
    new-instance v0, Ljava/security/spec/X509EncodedKeySpec;

    invoke-direct {v0, v2}, Ljava/security/spec/X509EncodedKeySpec;-><init>([B)V

    .line 187
    .local v0, "keySpec":Ljava/security/spec/X509EncodedKeySpec;
    const/4 v4, 0x0

    .line 189
    .local v4, "mPublicKey":Ljava/security/PublicKey;
    :try_start_0
    const-string v5, "RSA"

    invoke-static {v5}, Ljava/security/KeyFactory;->getInstance(Ljava/lang/String;)Ljava/security/KeyFactory;

    move-result-object v1

    .line 190
    .local v1, "kf":Ljava/security/KeyFactory;
    invoke-virtual {v1, v0}, Ljava/security/KeyFactory;->generatePublic(Ljava/security/spec/KeySpec;)Ljava/security/PublicKey;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    move-result-object v4

    .line 194
    .end local v1    # "kf":Ljava/security/KeyFactory;
    :goto_0
    return-object v4

    .line 191
    :catch_0
    move-exception v5

    goto :goto_0
.end method
```

Now bypassing this can be done in various different ways!
I opted for the, possibly, laziest way I could get away with!
Which was just to find a REALLY old version of the app which has not implemented this security check, 
and change the version numbers as showed above.
This allowed me to tamper with the app and recompile it as I saw fit!

Finding the old version was again just searching on Google for something like `bec apk download`.
But keep in mind! The APk you download might be infected with various crap and malware, so beware!

Another method I might do in the future, is just take a newer version of the app and overwrite the methods so it does not run all the `calculateKey` and `getOwnBytes` but just returns the public key, which should also be fairly simple!

Now I could write another chapter on how BEC could fix this, but as I am currently using this method to access my mobile banking, I would very much enjoy if this continued to work.

# References
- https://hub.docker.com/r/eyjhb/android-re
- https://github.com/eyJhb/docker-images/blob/master/tools/android-re/scripts/sign.sh
- https://www.airpair.com/android/posts/adding-tampering-detection-to-your-android-app
- https://stackoverflow.com/questions/6358247/detecting-debug-keystore-or-release-keystore-programmatically
