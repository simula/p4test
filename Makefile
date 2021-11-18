all:	forward.bmv2/forward.json learning.bmv2/learning.json

forward.bmv2/forward.json:	forward.p4
	p4c -b bmv2 forward.p4 -o forward.bmv2

learning.bmv2/learning.json:	learning.p4
	p4c -b bmv2 learning.p4 -o learning.bmv2

clean:
	rm -rf *.bmv2
