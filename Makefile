all:	forwarding.bmv2/forwarding.json learning.bmv2/learning.json

forwarding.bmv2/forwarding.json:	forwarding.p4
	p4c -b bmv2 forwarding.p4 -o forwarding.bmv2

learning.bmv2/learning.json:	learning.p4
	p4c -b bmv2 learning.p4 -o learning.bmv2

clean:
	rm -rf *.bmv2
