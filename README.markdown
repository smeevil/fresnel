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
    | 1 | M*** - 4***  | false  |            3 |
    | 2 | M*** - 5***  | false  |            9 |
    | 3 | M*** - E***  | false  |            2 |
    | 4 | M*** - R***  | false  |            4 |
    | 5 | SlickPics    | false  |           38 |
    +---+--------------+--------+--------------+


fresnel <tickets>

    Fetching unresolved tickets...
    +-----+-------+--------------------------------------------------------+-----------+
    |  #  | state |                         title                          |   tags    |
    +-----+-------+--------------------------------------------------------+-----------+
    | 100 |  new  | Ruby script om server updates te stroomlijnen          |           |
    |  99 |  new  | in dashboard stats create members weergeven            |           |
    |  97 |  new  | in sms_text add boolean wap_push_text                  |           |
    |  96 |  new  | Timetrace of posts , log in table url and time take... |           |
    |  83 | open  | css styling pagination                                 | high      |
    |  61 | open  | ie7 compatible                                         | high      |
    |  43 |  new  | 5959 in titel en afzender                              |           |
    |   2 |  new  | pretty urls en artist overviews                        | urls      |
    |   1 |  new  | toestellen weer geven bij javagames                    | javagames |
    +-----+-------+--------------------------------------------------------+-----------+


fresnel 2

    Fetching tickets #2...
    +-----------------------------------------------------------------------------+
    | Ticket #3 : Creating first ticket from fresnel                              |
    | Date : 02-12-09 16:12 by Smeevil                                            |
    | Tags : bogus high test                                                      |
    +-----------------------------------------------------------------------------+
    |                                                                             |
    | Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod    |
    | tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim        |
    | veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea     |
    | commodo consequat. Duis aute irure dolor in reprehenderit in voluptate      |
    | velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat  |
    | cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id   |
    | est laborum.                                                                |
    |                                                                             |
    | elit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat   |
    | cupidat                                                                     |
    |  at non proident, sunt in culpa qui officia deserunt mollit anim id est     |
    | laborum.                                                                    |
    |                                                                             |
    +-----------------------------------------------------------------------------+
    +-----------------------------------------------------------------------------+
    | Smeevil                                                      02-12-09 20:20 |
    +-----------------------------------------------------------------------------+
    |                                                                             |
    | seems to work                                                               |
    |                                                                             |
    +-----------------------------------------------------------------------------+
    | State changed from new => resolved                                          |
    +-----------------------------------------------------------------------------+
    Current state : resolved
    [q]uit, [t]ickets, [b]ins, [c]omment, [a]ssign, [r]esolve, [s]elf, [o]pen, [h]old, [w]eb
    Action : |q|