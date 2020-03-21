===
smf
===

.. contents::

Usage
=====

Format 0

うーん。どういうインタフェースがいいんだろう。

.. code-block:: nim

   import smf
   var smfw = openSMFWrite("out.mid")
   smfw.write(1, 0) # ピアノの音ON
   smfw.write(1, 0) # ピアノの音OFF
   smfw.write(1, 0) # ピアノの音ON
   smfw.write(1, 0) # ピアノの音OFF
   smfw.close()
