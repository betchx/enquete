


all:


%.pdf:%.dvi
	dvipdfmx $*
	cygstart $@


%.dvi:%.tex
	ebb $*/*.png
	platex $<
	platex $<


%.tex:%.rb  cross.rb
	ruby cross.rb $<


clean:
	for b in *.tex; do  for e in dvi log toc aux; do [ -f \$b.\$e ] && rm \$b.\$e ; done ; done


deepclean: clean
	for t in *.tex; do rm \$t ; done


.PHONY: all clean deepclean

