sequence
========
A sequence diagram writer, written in Ruby

command line
============

    > ruby sequence.rb -i "trace.txt" -o "sequence_diagram.txt"

If your trace.txt file contained:

      [2013-3-24 12:15:5:201] [00] cTrig->g() d211->d11 
      [2013-3-24 12:15:5:201] [00] cTrig->f() d11->d211 
      [2013-3-24 12:15:5:205] [00] cTrig->e() d211->d11 
      [2013-3-24 12:15:5:206] [00] cTrig->d() d11->d11
      [2013-3-24 12:15:5:206] [00] cTrig->c() d11->d211
      [2013-3-24 12:15:5:208] [00] cTrig->b() d211->d211
      [2013-3-24 12:15:5:209] [00] cTrig->a(Erker!) d211->d211

The sequence_diagram.txt would look like this:

      [ Chart: 00 ] (?)
           d11         d211     
            +----f()---->|
            |    (?)     |
            +            |
             \ (?)       |
             d()         |
             /           |
            <            |
            +----c()---->|
            |    (?)     |
            +<---g()-----|
            |    (?)     |
            +<---e()-----|
            |    (?)     |
            |            +            
            |             \ (?)       
            |             b()         
            |             /           
            |            <            
            |            +            
            |             \ (?)       
            |             a(Erker!)   
            |             /           
            |            <            
