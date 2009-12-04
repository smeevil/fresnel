Fresnel 
--------------

A console manager to LighthouseApp.com using the official lighthouse api

With Fresnel you can browse you complete lighthouse account.

Current features :
==================

- list projects
- list ticket bins
- list tickets (also in bins)
- create tickets
- assign tickets
- comment on tickets
- state changes


How to install
==============

Fresnel is available from gemcutter.org, so a 'gem install fresnel' should just work.

When you want to help develop Fresnel, look at the following rake tasks:

* rake gem
* rake install
* rake reinstall

Cache
=====

You can control the cache time in your global config file : ~/.fresnel

add a key like :
    cache_timeout: 60

This will set the timeout of the cache to 1 minute.
When fresnel makes changes, the cache will be invalidated automagically.
We would recommend to use a minimum of 10 seconds.

Terminal size
=============

By default we detect your terminal size,
if that fails it will be set to 80.
Though if you like to override it you can !

in your global config file : ~/.fresnel
add a key like :
    term_size: 60

The ticket overview table will add columns if it fits, in the following order :

* ticket number *
* state *
* title *
- assigned to
- by
- tags
- created at
- updated at

items with a * are always shown ;)

Getting started
===============

Once you have Fresnel installed, run 'fresnel help' to see the syntax.

Problems, Comments and Suggestions
==================================

Please post them on https://govannon.lighthouseapp.com/projects/42260-fresnel/
or mail it to : ticket+govannon.42260-7vwej7yr@lighthouseapp.com

Examples
========

fresnel help

    +---------------------------------------------------------------------------------------------------+
    | Fresnel - A lighthouseapp console manager - help                                                  |
    +---------------------------------------------------------------------------------------------------+
    |                                                                                                   |
    | Fresnel is a Console App that helps manage Lighthouse (LH).                                       |
    | You can find LH at http://lighthouseapp.com                                                       |
    |                                                                                                   |
    | fresnel help                                       This screen                                    |
    | fresnel bins                                       Show all ticket bins                           |
    | fresnel bin <id>                                   Show ticket in bin <id>                        |
    | fresnel projects                                   Show all projects                              |
    | fresnel <id> comment                               Show comments for ticket                       |
    | fresnel <id>                                       Show ticket details                            |
    | fresnel <id> assign                                Assign ticket to user                          |
    | fresnel <id> claim                                 Assign ticket to self                          |
    | fresnel <id> links                                 Extract all links from the ticket and its      |
    | comment and open one in your browser.                                                             |
    | fresnel <id> online                                Open browser for ticket                        |
    | fresnel <id> [open|closed|hold|resolved|invalid]   Change ticket state                            |
    | fresnel tickets                                    Show all tickets                               |
    | fresnel create                                     Create a ticket                                |
    |                                                                                                   |
    +---------------------------------------------------------------------------------------------------+
    | Created by Narnach & Smeevil - licence : mit                                                      |
    +---------------------------------------------------------------------------------------------------+

fresnel projects

    fetching projects...
    +---+--------------+--------+--------------+
    | # | project name | public | open tickets |
    +---+--------------+--------+--------------+
    | 0 | Fresnel      | true   |            3 |
    | 1 | Rails        | true   |          123 |
    +---+--------------+--------+--------------+


fresnel tickets

    Fetching unresolved tickets...
    +----+-------+--------------------------------------------------------+--------+------------------+-------------+----------------+----------------+
    | #  | state |                         title                          |  tags  |        by        | assigned to | created at     | updated at     |
    +----+-------+--------------------------------------------------------+--------+------------------+-------------+----------------+----------------+
    | 10 |  new  | Add option to open Hoptoad link in browser             | medium | Wes Oldenbeuving | nobody      |    Today 11:22 |    Today 11:23 |
    |  9 |  new  | cache invalidation                                     | medium | Smeevil          | nobody      |    Today 08:17 |    Today 08:18 |
    |  6 | open  | would be nice if we could create a new lighthouse p... | low    | Smeevil          | Smeevil     | 02-12-09 22:10 | 02-12-09 22:16 |
    +----+-------+--------------------------------------------------------+--------+------------------+-------------+----------------+----------------+

fresnel 6

    +-----------------------------------------------------------------------------+
    | Ticket #6 : would be nice if we could create a new lighthouse projec...     |
    | Date : 02-12-09 22:10 by Smeevil                                            |
    | Tags : low                                                                  |
    +-----------------------------------------------------------------------------+
    |                                                                             |
    |                                                                             |
    +-----------------------------------------------------------------------------+

    Assignment changed 02-12-09 21:14 => Smeevil by Smeevil

    +-----------------------------------------------------------------------------+
    | Smeevil                                                      02-12-09 21:24 |
    +-----------------------------------------------------------------------------+
    |                                                                             |
    | seems its changing state !                                                  |
    | now lets see if we can do it again !                                        |
    |                                                                             |
    +-----------------------------------------------------------------------------+
    | Assignment changed => Wes Oldenbeuving                                      |
    +-----------------------------------------------------------------------------+

    Assignment changed 02-12-09 22:10 => Smeevil by Smeevil

    Current state : open

fresnel 10 links

    +---+------------------------------------------------------------------------------------------------------+
    | # | link                                                                                                 |
    +---+------------------------------------------------------------------------------------------------------+
    | 0 | http://upnextinsports.com/wp-content/uploads/2009/11/sports-pictures-baseball-tractor-beam.jpg       |
    | 1 | http://upnextinsports.com/wp-content/uploads/2009/10/sports-pictures-HHH-orton-miracle-superglue.jpg |
    | 2 | http://www2.printshop.co.uk/Weebl/Shop/Plushies/Magical_Trevor_Plushie/Product.html                  |
    | 3 | http://bit.ly/4wZKb                                                                                  |
    | 4 | http://media.photobucket.com/image/fail/penguinking3/fail.jpg                                        |
    | 5 | http://www.realfreewebsites.com/blog/img/fail.jpg                                                    |
    | 6 | www.illwillpress.com                                                                                 |
    | 7 | www.govannon.nl/portfolio                                                                            |
    +---+------------------------------------------------------------------------------------------------------+
