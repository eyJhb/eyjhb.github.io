---
layout: post
author: eyJhb
title:  "Ingenico - Built to fail"
date:   2019-03-07 18:00:00 +0000
categories: repair
---
Recently I were at [Krop-Sind-Ånd Messerne](https://www.daninfo.dk/) working at the entrance, accepting payments, checking guest lists etc.
But not many hours in, the payment terminal started to show signs of low battery, and the charging base station were pulled out to charge it.
Little did I know that there had been trouble with it, and the cable/port needed to be positioned exactly right, for it to charge.
Looking at the charging station, it was clear that the port in the charging station was loose and clearly a connection was broken (as the owner also suspected).
Knowing the owner of event, I asked if I could take it home to look at and maybe repair!

| ![](/assets/images/ingenico-top.jpg) | ![](/assets/images/ingenico-side.jpg) | ![](/assets/images/ingenico-broken.jpg) |
|:---:|:---:|:---:|
| Top View | Back View | Broken Connector |

Above are the images I took of it.
It is a simple piece of plastic which exposes basic charging terminals where the payment terminal plugs in.
After removing the three screws that held it all together, I could easily feel that the port was loose and I only needed to desolder one pin out of three to get it off.
Looking at how the component was mounted, it became very apparent as to why the two pins had broken off at the base of the component.
As there is nothing holding the component in place, except the actual connections going from the PCB to it, it becomes very brittle and weak (not suited for being used as a port that is plugged in/out all the time).
The port should be fastened to the board using additional fastening points, which is normally done using two metal pieces on each side of the component, that will go down into the PCB and soldered down, which will prevent the adapter from wiggling and breaking off the real connections.

To fix this I got a new adapter from the University I am currently studying at, made two additional holes (one on each side) and got some mounting wire that I could bend into place.
The final product ended up looking like below.

| ![](/assets/images/ingenico-fixed-back.jpg) | ![](/assets/images/ingenico-fixed-top.jpg) |
|:---:|:---:|:---:|
| Fixed Backside | Fixed Backside|

The end result is a adaptor port which does not wiggle at all and very solid in its place.
It baffles me that Ingenico will place such a lousy component on their PCB, that easily costs 1.000,- DKK (134 Euro) from new; which is also outrageous considering what actual production costs are.
So my conclusion is that they must have designed it to fail, so that Ingenico can make money from their bad design. 
