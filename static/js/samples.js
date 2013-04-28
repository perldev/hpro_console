   var  SampleCode = {
	  "any_queens" : 
	  "\n\
%%call common_queens(9,X) for any number \n\
gen( N, N, [N]).\n\
\n\
gen( Nl, N2, [Nl | Tail]) :-\n\
                    Nl < N2,\n\
                    M is Nl + 1,\n\
                    gen( M, N2, Tail)\n\
.\n\
\n\
\n\
common_queens( N, S) :-\n\
		gen( 1, N, Dxy),\n\
                Nu1 is 1 - N,\n\
                Nu2 is N - 1,\n\
                gen( Nu1, Nu2, Du),\n\
                Nv2 is N + N,\n\
                gen( 2, Nv2, Dv),\n\
                get_common_res( S, Dxy, Dxy, Du, Dv).\n\
\n\
get_common_res([ ], [ ], Dy, Du, Dv):- true.\n\
\n\
get_common_res( [Y | ListY], [X | Dx1], Dy, Du, Dv) :-\n\
        del( Y, Dy, Dy1), \n\
        U is X-Y,del( U, Du, Du1),V is X+Y,del( V, Dv, Dv1),get_common_res( ListY, Dx1, Dy1, Du1, Dv1).\n\
\n\
del( A, [A | Tail], Tail).\n\
\n\
del(A, [B | Tail], [B | Tail1 ] ) :-\n\
        del( A, Tail, Tail1).\n\
	\n\
	  ",
	  "queens_8":
	  "%call pattern(S),call_chess(S). for find how place 8 queens on chess board \n\
	  \n\
pattern( [1/Y1, 2/Y2, 3/Y3, 4/Y4, 5/Y5, 6/Y6, 7/Y7, 8/Y8]).\n\
\n\
call_chess([]):-true.\n\
call_chess( [X/Y | Last] ):-\n\
               call_chess( Last),\n\
               has( Y, [1, 2, 3, 4, 5, 6, 7, 8] ),\n\
               not_beat( X/Y, Last).\n\
has( X, [X | L] ):- true. \n\
has( X, [Y | L] ) :- has( X, L).\n\
not_beat( Something, []).\n\
not_beat( X/Y, [X1/Y1 | Last] ) :-\n\
	    Y =\= Y1,\n\
	    Y1-Y =\= X1-X, \n\
            Y1-Y =\= X-X1,\n\
            not_beat( X/Y, Last).\n\
	  "
	  ,
	  "simple_recursion":
"%concat  tow lists add([5,6,7,8],[r],X).\n\
add([],X,X):-true.\n\
add([ X| R1 ],R2,[X|R3] ):-\n\
  add(R1,R2,R3).\n\
parent(pam, bob).\n\
parent(tom, bob).\n\
parent(tom, liz).\n\
parent(bob, ann).\n\
parent(bob, pat).\n\
parent(pat, jim).\n\
%checking all parents like this predecessor(X, jim) \n\n\
predecessor(X, Y) :- parent(X, Y).\n\
predecessor(X, Y) :-\n\
	parent(X, Z),\n\
	predecessor(Z, Y).\n\
%calculate facrtorial \n\
fact(1,1):- !.\n\
fact(N,R):-N1 is N-1,fact(N1,R1),R is R1*N.\n\
"
,
	  "simple_operation":  
	  "%arithmetic operation \n\
what(X):- X is 5+6.\n\
% working with structures \n\
match(X,Y,Z):- X = fact1(4,6), Y = fact2(8), Z = X + Y.\n\
%facts about pam,liz, ann, pat \n\
female(pam).\n\
female(liz).\n\
female(ann).\n\
female(pat).\n\
%and mans tom, bob, jim, pam\n\
male(tom).\n\
male(bob).\n\
male(jim).\n\
male(pam).\n\
	  "
     
     
     
     
  };
	       
