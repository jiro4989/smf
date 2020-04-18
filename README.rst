===
smf
===

``smf`` is a low level Standard MIDI File (SMF) module.
This module is supported only ``MIDI Format 0``.
You must understand SMF if you want to use this module.

.. contents::

Installation
============

.. code-block:: Bash

   nimble install smf

Usage
=====

Reading example
---------------

.. code-block:: nim

   TODO

Writing example
---------------

.. code-block:: nim

   import smf

   var smf = openSmfWrite("out.mid")
   let
     channel = 0'u8
     velocity = 100'u8
   for note in 49'u8 .. 68'u8:
     smf.writeMidiNoteOn(0'u32, channel, note, velocity)
     smf.writeMidiNoteOff(120'u32, channel, note)
   smf.close()

Writing MIDI tutorial
=====================

See `tutorial <./docs/tutorial.rst>`_.

API document
============

* https://jiro4989.github.io/smf/smf.html

Pull request
============

Welcome :heart:

LICENSE
=======

MIT

See also
========

English
-------

TBD

Japanese
--------

* `SMF(Standard MIDI File)フォーマット解説 | 技術的読み物 | FISH&BREAD <http://maruyama.breadfish.jp/tech/smf/>`_
* `JavaScriptでMIDIファイルを解析してみる 1 - Qiita <https://qiita.com/PianoScoreJP/items/2f03ae61d91db0334d45>`_
* `SMF (Standard MIDI Files) の構造 - Welcome to yyagi's web site. <https://sites.google.com/site/yyagisite/material/smfspec#MIDIevent>`_
