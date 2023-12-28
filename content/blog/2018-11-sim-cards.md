---
author: eyJhb
categories: scam
date: "2018-11-04T18:00:00Z"
title: The reason I have 500+ SIM Cards
---
Over the past couple of years, I have been asked numerous time why I have such a huge amount of SIM cards.
Most seem to think I either use them for drug dealing, smuggling or work for a phone company, but it is actually none of it!

![SIM cards](/assets/images/sim-stacked.jpg)

## Background
SIM cards can be used for various things, where most of these might not be obvious.
I started gathering SIM cards to use for verification, when I need to sign-up to a website that required verification for proving that "you are not a single person creating lots of accounts" (yeah, good luck with that!).

So I basically found various places that offered me to get free SIM cards, without having to enter any credit card details or have a payment plan.
Most of these SIM cards did not have any credit on them (if you were lucky, you found one that had 10,- DKK of credit to begin with), as they were purely a way for people to get access to a card, and then fill it up at the nearest kiosk or convenience store.
But for my use case, credit was not needed at all since all I required, was to receive messages and never to send any messages.

What I did was to observe the HTTP traffic when a SIM card was ordered, create a python script to emulate this, add it to my crontab on my server and watch my mailbox get flooded.
At that time I lived at home and my parents were not quite as enthusiastic about it, as I was...

But when you have such an amount of SIM cards, you need a way to organize it and most of the time each SIM card would also have a unique fake person attached to it.
The reason for this was, that the various sites I have used these SIM cards on have been sites such as online competitions and answer surveys to earn money.
Therefore each SIM card I have and is in use, have a label on it with a unique increasing number, that corresponds to a excel sheet I used.
This was a huge amount of work, since you first had to unpack all the SIM cards, then label put all the information into the excel sheet (including turning on the phone, get the number, write it down, write the PUK1/PUK2, PIN and the SIM card number).

![SIM ordered](/assets/images/sim-ordered.jpg)

This it what my organized drawer looks like, where there is N amounts of SIM cards in each slot, that makes it relatively easy to find the SIM card you are looking for.


## Story time!
I have some stories, that I would like to share with you guys, even though some of the details have been left out.

### Send SMS to ...  and get one month free trail!
Sometimes you will see a campaign, where you can get one month free trail if you send a SMS to some number.
So if you remember earlier when I said, that if you were lucky you find a provider which gives you some free credit.
This enables you to fuck with those kind of campaigns!
Basically just put in the SIM card, send the SMS, receive the code and ... PROFIT!

But wait, there is more.. One of such campaigns had a error, where you were able to stack these coupons/codes.
This meant for me, that I were able to continue receiving my one free month trail over and over again and activate it on my account!
In a little less than a week some ended up with a accounts for TV2 Play all-inclusive that would expire in 21 years, for the great deal of 0 DKK. 

### Online Competitions - refer a friend
So when I see a online competition where you can refer a friend, I suddenly get a whole lot of friends to play with!
As each of my SIM cards has a unique identity attached to it (including e-mail), this allows me to use them for this purpose.

There once were a competition where you had a slot machine and you needed the same symbol three times (as usual).
Once you span the slot machine, all the three wheels would spin and stop at some random block. 
If the block stopped at the right symbol, that block would stay and only the others would spin.

They then allowed you to a invite a friend, that would then continue to spin on from the point you reached!
This was great, as it enabled me to setup a simple Python script to play the game, and if I only needed one more to win I would just refer myself again!

### Online surveys and rating/watching commercials
There are such sites as Eovendo that allows you to watch videos and answer surveys for money.
You just sign-up and you can start watching videos and answer surveys, and earn around 0,25 DKK which is great!
The only problem was, that for it to payout you needed to validate your account with (guess what!) a phone number..

But this was no problem at all! Since I could just order as many (almost) as I wanted for free!
So if you added all this up, you quickly ended up with a somewhat good amount of money each week that you could use on whatever you wanted.

Later on they required NemID validation, which were not quite as easy to get your hands on.

## Ending notes 
Remember I am not liable for any shit you do regarding this.

Also, if you forget to remove your SIM card orderer from your crontab, some companies might get somewhat angry with you and start sending threatening letters.
The best part about that properly was that all the contact information except my address where invalid, so they had to send me a letter addressing the issue.
Needless to say, they were very unhappy with me as they manually had to cancel my orders for free SIM cards each morning.
