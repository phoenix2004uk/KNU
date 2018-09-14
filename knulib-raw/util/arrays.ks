{

	LOCAL array_search IS {
		PARAMETER needle, haystack.
		LOCAL index IS 0.
		UNTIL index = haystack:LENGTH {
			IF haystack[index]=needle RETURN index.
			SET index TO index + 1.
		}
		RETURN -1.
	}.

	// compares the first matchCount elements of listA and listB and returns TRUE if they are equal
	// if matchCount is 0, then all elements are checked
	// if matchLength IS TRUE, then both lists must be the same size
	LOCAL compare IS {
		PARAMETER listA, listB, matchCount IS 0, matchLength IS TRUE.
		IF matchLength AND listA:LENGTH<>listB:LENGTH RETURN FALSE.
		IF matchCount < 1 SET matchCount TO listA:LENGTH.
		LOCAL index IS 0.
		UNTIL index=MIN(matchCount,MIN(listA:LENGTH,listB:LENGTH)) {
			IF listA[index] <> listB[index] RETURN FALSE.
			SET index TO index + 1.
		}
		RETURN TRUE.
	}.

	LOCAL usort IS {
		PARAMETER array,cmp.

		LOCAL done IS FALSE.
		UNTIL done {
			SET done TO TRUE.
			LOCAL index IS 0.
			UNTIL index >= array:LENGTH - 1 {
				IF cmp(array[index], array[index+1]) > 0 {
					LOCAL tmp IS array[index+1].
					SET array[index+1] TO array[index].
					SET array[index] TO tmp.
					SET done TO 0.
				}
				SET index TO index + 1.
			}
		}

		RETURN array.
	}.

	export(Lex(
		"version", "1.2.0",
		"search", array_search,
		"compare", compare,
		"usort", usort
	)).
}