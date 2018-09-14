{
	LOCAL CallbackIterator IS {
		PARAMETER iter,cb.
		UNTIL NOT iter:NEXT cb(iter:VALUE,iter:INDEX).
	}.

	LOCAL PatternFilterIterator IS {
		PARAMETER iter,pattern,cb.
		LOCAL onItem IS {
			PARAMETER pattern, originalCB, current, index.
			IF current:MATCHESPATTERN(pattern) originalCB(current, index).
		}.
		iter(onItem:bind(pattern):bind(cb)).
	}.

	LOCAL TypeFilterIterator IS {
		PARAMETER iter,type,cb.
		LOCAL onItem IS {
			PARAMETER type, originalCB, current, index.
			IF item:ISTYPE(type) originalCB(current, index).
		}.
		iter(onItem:bind(type):bind(cb)).
	}.

	export(Lex(
		"version", "1.0.0",
		"CallbackIterator", CallbackIterator,
		"PatternFilterIterator", PatternFilterIterator,
		"TypeFilterIterator", TypeFilterIterator
	)).
}