#! /bin/bash


#stg=chk
stgs="chk" # chk-arg"
ori=complex-cross.rb
new=cross.rb

function fail_message(){
#echo fail_messege called with $*
echo execution of $1 $2.rb for $3 was failed.
if [ `wc -l $4` < 10 ]
then
  nkf -w $4
else
  echo check $4 for details
fi
}

function ruby_run(){
#echo ruby_run called with $*
msg=$4.msg
(ruby $1 $2.rb out.$3 2> $msg ) && rm $msg
if [ -f $msg ]
then
  # failed
  fail_message $1 $2 $3 $msg
  return 1
else
  mv out.$3 $4.$3
  return 0
fi
}


for stg in $stgs
do
  if [ -f $stg.rb ]
  then
    for ext in tex csv
    do
      # test new one
      ruby_run $new  $stg  $ext  "new"  && \
        ruby_run $ori $stg  $ext  "ori"  && \
          (diff -C 3 ori.$ext new.$ext > diff-out.log) && rm diff-out.log
      if [ -f diff-out.log ];
      then
        #fail
        out=diff-out.$stg.$ext.log
        mv diff-out.log $out
        echo ori.$ext and new.$ext differ.
        if [ `wc -l $out` < 15 ]
        then
          # short diff
          nkf -w $out
        else
          #long diff
          echo please see $out for details
        fi
      else
        #Passed
        echo Test of $stg for $ext was passed.
        rm ori.$ext new.$ext
        if [ -d out ]; then rmdir out; fi
      fi
    done
  else
    echo Setting file $stg.rb was not found. Test was skipped.
  fi
done

