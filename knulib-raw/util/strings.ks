{
	LOCAL substr IS {
		PARAMETER value, start, length IS FALSE.
		SET value TO ""+value.
		IF start<0 SET start TO value:LENGTH+start.
		IF start>value:LENGTH RETURN "".
		IF JF(length) SET length TO MAX(0, value:LENGTH - start).
		IF length < 0 SET length TO MAX(0, value:LENGTH - start + length).
		RETURN value:SUBSTRING(start, length).
	}.

	LOCAL ltrim IS {
		PARAMETER value, char IS " ".
		SET value TO ""+value.
		IF value:STARTSWITH(char) {
			LOCAL index IS 0.
			UNTIL index = value:LENGTH {
				IF value[index] <> char RETURN substr(value, index).
				SET index TO index + 1.
			}
			RETURN "".
		}
		RETURN value.
	}.

	LOCAL rtrim IS {
		PARAMETER value,char IS " ".
		SET value TO ""+value.
		IF value:ENDSWITH(char) {
			LOCAL index IS value:LENGTH - 1.
			UNTIL index < 0 {
				IF value[index] <> char RETURN substr(value, 0, index+1).
				SET index TO index - 1.
			}
			RETURN "".
		}
		RETURN value.
	}.

	LOCAL trim IS {
		PARAMETER value,char IS " ".
		RETURN ltrim(rtrim(value,char),char).
	}.

	LOCAL str_repeat IS {
		PARAMETER value, length.
		SET value TO ""+value.
		LOCAL str IS "".
		UNTIL length < 1 {
			SET str TO str + value.
			SET length TO length - 1.
		}
		RETURN str.
	}.

	LOCAL STR_PAD_LEFT IS -1.
	LOCAL STR_PAD_BOTH IS 0.
	LOCAL STR_PAD_RIGHT IS 1.
	Local str_pad IS {
		PARAMETER value, pad_length, pad_string IS " ", pad_direction IS STR_PAD_RIGHT.
		SET value TO ""+value.
		LOCAL repeat_length IS pad_length - value:LENGTH.
		IF repeat_length < 1 RETURN value.
		LOCAL padding IS str_repeat(pad_string, repeat_length).
		IF pad_direction = STR_PAD_LEFT RETURN padding + value.
		IF pad_direction = STR_PAD_RIGHT RETURN value + padding.
		RETURN substr(padding,0,FLOOR(repeat_length/2)) + value + substr(padding,FLOOR(repeat_length/2)).
	}.

	LOCAL vsprintf IS {
		PARAMETER format, args.
		LOCAL mapValues IS args.
		IF NOT args:IsType("Lexicon") {
			SET mapValues TO Lex().
			LOCAL iter IS args:ITERATOR.
			UNTIL NOT iter:NEXT {
				SET mapValues[iter:INDEX] TO iter:VALUE.
			}
		}
		LOCAL value IS format.
		FOR key IN mapValues:KEYS {
			SET value TO value:REPLACE("{"+key+"}", ""+mapValues[key]).
		}
		RETURN value.
	}.

	export(Lex(
		"version", "1.0.1",
		"substr", substr,
		"ltrim", ltrim,
		"rtrim", rtrim,
		"trim", trim,
		"str_repeat", str_repeat,
		"str_pad", str_pad,
		"vsprintf", vsprintf
	)).
}