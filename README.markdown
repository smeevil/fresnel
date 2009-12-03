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

Use 'rake gem' to build the gem or 'rake install' to build and install the gem.

Getting started
===============

Once you have Fresnel installed, run 'fresnel help' to see the syntax.

Examples
========

fresnel help

    +-----------------------------------------------------------------------------+
    | Fresnel - A lighthouseapp console manager - help                            |
    +-----------------------------------------------------------------------------+
    |                                                                             |
    | Fresnel is a Console App that helps manage Lighthouse (LH).                 |
    | You can find LH at http://lighthouseapp.com                                 |
    |                                                                             |
    | fresnel help                                       This screen              |
    | fresnel bins                                       Show all ticket bins     |
    | fresnel bin <id>                                   Show ticket in bin <id>  |
    | fresnel projects                                   Show all projects        |
    | fresnel <id> comment                               Show comments for ticket |
    | fresnel <id>                                       Show ticket details      |
    | fresnel <id> assign                                Assign ticket to user    |
    | fresnel <id> claim                                 Assign ticket to self    |
    | fresnel <id> online                                Open browser for ticket  |
    | fresnel <id> [open|closed|hold|resolved|invalid]   Change ticket state      |
    | fresnel tickets                                    Show all tickets         |
    | fresnel create                                     Create a ticket          |
    |                                                                             |
    +-----------------------------------------------------------------------------+
    | Created by Narnach & Smeevil - licence : mit                                |
    +-----------------------------------------------------------------------------+

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
