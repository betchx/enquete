#! /bin/bash


stg=chk
ori=complex-cross.rb
new=cross.rb

for ext in tex csv
do
  (ruby $new $stg.rb out.$ext 2> /dev/null)|| ruby $new $stg.rb out.$ext || exit
  mv out.$ext new.$ext
  (ruby $ori $stg.rb out.$ext 2> /dev/null)|| exit
  mv out.$ext ori.$ext
    (if [ -d out ]; then rmdir out; fi) && \
    echo Test for $ext was passed.
done

