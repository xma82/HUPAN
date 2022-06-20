../../bin/ccov:
	g++ -O2 -o ../../bin/ccov CCOV.cpp GTF.cpp -lz -lbamtools -L ../../lib/ -I ../../lib/include/ -D_GLIBCXX_USE_CXX11_ABI=0
clean:
	rm ../../bin/ccov
debug:
	g++ -g -o ../../bin/ccov CCOV.cpp GTF.cpp -lz -lbamtools -L ../../lib/ -I ../../lib/include/ -D_GLIBCXX_USE_CXX11_ABI=0
