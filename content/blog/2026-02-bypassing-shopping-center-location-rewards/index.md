---
author: eyJhb
date: "2026-02-14T10:00:00Z"
title: Bypassing shopping center reward system
draft: true
---

Back in ~2023 it was brought to my attention that some shopping centers provide rewards if you open the app each day while inside the shopping center.
The app would somehow know that you were at the shopping center, and I initially thought that it was just based on the GPS position and therefore tried to fake it.
Faking the GPS location did not work, however, I then started investigating how the app worked, and how one might be able to exploit this reward system.

I saw a lot of references to Bluetooth in the app, and could see that the app required Bluetooth permission to work as well, which made sense.
While visiting the shopping center, I opened [nRF Connect for Mobile](https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp) and tried looking at what devices I could see.
I found some iBeacon devices in the device list, which I only knew in relation to Apple, and was not really sure why they were at the shopping center.

![nrf connect showing ibeacon device](nrf-connect.png)

Searching for the UUID4 in the decompiled app source code, we find this.

```java
public final class TrackingRegion$Companion {
    ...
   public final TrackingRegion createDefault(int var1) {
      return new TrackingRegion("F7826DA6-4FA2-4E98-8024-BC5B71E0893E", var1, (p)null);
   }
   ...
}
```

It does however take an argument, which can be found in a different file and turns out to be `168`.

```java
public final class AppStrategiesFactory extends DscDefaultStrategiesFactory {
    ...
   private final TrackingRegion trackingRegion;

   private AppStrategiesFactory() {
      this.trackingRegion = TrackingRegion.Companion.createDefault(168);
      ...
   }
   ...
}
```

Looking at the iBeacon information from nRF Connect, we can see that the number we found is the major value.
The major value is used to identify which shopping center the phone is currently in, which can be verified by decompiling other apps.

Knowing this information, it is now possible to replicate the iBeacon device using a nrf52840 development kit.
The code is fairly simple to write, as there is an example available over at [Zephyr](https://github.com/zephyrproject-rtos/zephyr/tree/1b23efc6121eedac9f30391265f767c1f232724c/samples/bluetooth/ibeacon) on how to make an iBeacon device.

The code will then just loop over the list of major values from different shopping centers, broadcast an iBeacon advertisement, sleep, broadcast the next, and so on.
While it is doing this, the app can be opened and the reward can be redeemed from the shopping center the device is currently broadcasting.


```c
#include <zephyr/types.h>
#include <stddef.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/util.h>

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/hci.h>

#ifndef IBEACON_RSSI
#define IBEACON_RSSI 0xc8
#endif

#define IBEACON_SWITCH_TIME 5 * 1000

struct shopping_center {
    uint8_t major1, major2;
};

struct shopping_center shopping_centers[] = {
    {0x00, 0x40}, // shopping center 1
    {0x00, 0xa8}, // shopping center 2
    {0x00, 0x8a}, // shopping center 3
};

static void bt_ready(int err)
{
	if (err) {
		printk("Bluetooth init failed (err %d)\n", err);
		return;
	}

	printk("Bluetooth initialized\n");
	printk("Starting advertising iBeacon\n");

    for (int i = 0;; i++) {
        // select the correct shopping center that we want to advertise
        uint8_t major1 = shopping_centers[i % sizeof(shopping_centers)/sizeof(shopping_centers[0])].major1;
        uint8_t major2 = shopping_centers[i % sizeof(shopping_centers)/sizeof(shopping_centers[0])].major2;

        printk("Advertising major1: %x \t major2: %x\n", major1, major2);

        /*
        * iBeacon Shopping Centers
        *
        * UUID:  F7826DA6-4FA2-4E98-8024-BC5B71E0893E
        * Major: taken from `shopping_centers`
        * Minor: 0 
        * RSSI:  -56 dBm
        */
        struct bt_data ad[] = {
            BT_DATA_BYTES(BT_DATA_FLAGS, BT_LE_AD_NO_BREDR),
            BT_DATA_BYTES(BT_DATA_MANUFACTURER_DATA,
                          0x4c, 0x00, /* Apple */
                          0x02, 0x15, /* iBeacon */
                          0xf7, 0x82, 0x6d, 0xa6, /* UUID[15..12] */
                          0x4f, 0xa2, /* UUID[11..10] */
                          0x4e, 0x98, /* UUID[9..8] */
                          0x80, 0x24, /* UUID[7..6] */
                          0xbc, 0x5b, 0x71, 0xe0, 0x89, 0x3e, /* UUID[5..0] */
                          major1, major2, /* Major STORCENTER */
                          0x00, 0x00, /* Minor */
                          IBEACON_RSSI) /* Calibrated RSSI @ 1m */
        };

        // start advertising
        err = bt_le_adv_start(BT_LE_ADV_NCONN, ad, ARRAY_SIZE(ad), NULL, 0);
        if (err) {
            printk("Advertising failed to start (err %d)\n", err);
            return;
        }
  
        // sleep before next advertising
        k_msleep(IBEACON_SWITCH_TIME);
  
        // stop advertising
        bt_le_adv_stop();
    }

}

int main(void)
{
	int err;

	printk("Starting iBeacon Demo\n");

	/* Initialize the Bluetooth Subsystem */
	err = bt_enable(bt_ready);
	if (err) {
		printk("Bluetooth init failed (err %d)\n", err);
	}
	return 0;
}
```

The full code can be found [here](https://github.com/eyJhb/nrf-shopping-mall-simulator).

This was a fun little project to work on, especially as it involved reverse engineering and making some basic hardware.
It could be made a lot easier, if the app was reverse engineered further and just making the correct API calls instead, as the server does not check if you are actually at shopping center (i.e. there is no challenge).
