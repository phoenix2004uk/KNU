{
	//substr PARAMETER value, start, length IS 0.
	FUNCTION test_substr {
		LOCAL substr IS Libs["util/strings"]["substr"].
		IF NOT assertEqual("substr('foobar', 0)",		substr("foobar", 0),			"foobar")			RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 0, 0)",	substr("foobar", 0, 0),			"")					RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 1)",		substr("foobar", 1),			"oobar")			RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 0, 3)",	substr("foobar", 0, 3),			"foo")				RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 3, 3)",	substr("foobar", 3, 3),			"bar")				RETURN FALSE..
		IF NOT assertEqual("substr('foobar', -3)",		substr("foobar", -3),			"bar")				RETURN FALSE.
		IF NOT assertEqual("substr('foobar', -3, 2)",	substr("foobar", -3, 2),		"ba")				RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 0, -3)",	substr("foobar", 0, -3),		"foo")				RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 2, -2)",	substr("foobar", 2, -2),		"ob")				RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 9)",		substr("foobar", 9),			"")					RETURN FALSE.
		IF NOT assertEqual("substr('foobar', 0, -9)",	substr("foobar", 0, -9),		"")					RETURN FALSE.

		RETURN TRUE.
	}

	// ltrim PARAMETER value,char.
	FUNCTION test_ltrim {
		LOCAL ltrim IS Libs["util/strings"]["ltrim"].
		IF NOT assertEqual("ltrim('')",					ltrim(""),						"")					RETURN FALSE.
		IF NOT assertEqual("ltrim('    ')",				ltrim("    "),					"")					RETURN FALSE.
		IF NOT assertEqual("ltrim('  foobar')",			ltrim("  foobar"),				"foobar")			RETURN FALSE.
		IF NOT assertEqual("ltrim('foobar  ')",			ltrim("foobar  "),				"foobar  ")			RETURN FALSE.
		IF NOT assertEqual("ltrim('  foobar  ')",		ltrim("  foobar  "),			"foobar  ")			RETURN FALSE.
		IF NOT assertEqual("ltrim('  foobar  ','/')",	ltrim("  foobar  ","/"),		"  foobar  ")		RETURN FALSE.
		IF NOT assertEqual("ltrim('/','/')",			ltrim("/","/"),					"")					RETURN FALSE.
		IF NOT assertEqual("ltrim('/foo/bar','/')",		ltrim("/foo/bar",				"/"),"foo/bar")		RETURN FALSE.
		IF NOT assertEqual("ltrim('/foo/bar/','/')",	ltrim("/foo/bar/",				"/"),"foo/bar/")	RETURN FALSE.
		IF NOT assertEqual("ltrim('////','/')",			ltrim("////","/"),				"")					RETURN FALSE.
		IF NOT assertEqual("ltrim('////','//')",		ltrim("////","//"),				"////")				RETURN FALSE.

		RETURN TRUE.
	}

	// rtrim PARAMETER value,char.
	FUNCTION test_rtrim {
		LOCAL rtrim IS Libs["util/strings"]["rtrim"].
		IF NOT assertEqual("rtrim('')",						rtrim(""),						"")				RETURN FALSE.
		IF NOT assertEqual("rtrim('    ')",					rtrim("    "),					"")				RETURN FALSE.
		IF NOT assertEqual("rtrim('  foobar')",				rtrim("  foobar"),				"  foobar")		RETURN FALSE.
		IF NOT assertEqual("rtrim('foobar  ')",				rtrim("foobar  "),				"foobar")		RETURN FALSE.
		IF NOT assertEqual("rtrim('  foobar  ')",			rtrim("  foobar  "),			"  foobar")		RETURN FALSE.
		IF NOT assertEqual("rtrim('  foobar  ','/')",		rtrim("  foobar  ","/"),		"  foobar  ")	RETURN FALSE.
		IF NOT assertEqual("rtrim('/','/')",				rtrim("/","/"),					"")				RETURN FALSE.
		IF NOT assertEqual("rtrim('/foo/bar','/')",			rtrim("/foo/bar","/"),			"/foo/bar")		RETURN FALSE.
		IF NOT assertEqual("rtrim('/foo/bar/','/')",		rtrim("/foo/bar/","/"),			"/foo/bar")		RETURN FALSE.
		IF NOT assertEqual("rtrim('////','/')",				rtrim("////","/"),				"")				RETURN FALSE.
		IF NOT assertEqual("rtrim('////','//')",			rtrim("////","//"),				"////")			RETURN FALSE.

		RETURN TRUE.
	}

	// trim PARAMETER value,char.
	FUNCTION test_trim {
		LOCAL trim IS Libs["util/strings"]["trim"].
		IF NOT assertEqual("trim('')",						trim(""),						"")				RETURN FALSE.
		IF NOT assertEqual("trim('    ')",					trim("    "),					"")				RETURN FALSE.
		IF NOT assertEqual("trim('  foobar')",				trim("  foobar"),				"foobar")		RETURN FALSE.
		IF NOT assertEqual("trim('foobar  ')",				trim("foobar  "),				"foobar")		RETURN FALSE.
		IF NOT assertEqual("trim('  foobar  ')",			trim("  foobar  "),				"foobar")		RETURN FALSE.
		IF NOT assertEqual("trim('  foobar  ','/')",		trim("  foobar  ","/"),			"  foobar  ")	RETURN FALSE.
		IF NOT assertEqual("trim('/','/')",					trim("/","/"),					"")				RETURN FALSE.
		IF NOT assertEqual("trim('/foo/bar','/')",			trim("/foo/bar","/"),			"foo/bar")		RETURN FALSE.
		IF NOT assertEqual("trim('/foo/bar/','/')",			trim("/foo/bar/","/"),			"foo/bar")		RETURN FALSE.
		IF NOT assertEqual("trim('////','/')",				trim("////","/"),				"")				RETURN FALSE.
		IF NOT assertEqual("trim('////','//')",				trim("////","//"),				"////")			RETURN FALSE.

		RETURN TRUE.
	}

	//str_repeat PARAMETER value, length.
	FUNCTION test_str_repeat {
		LOCAL str_repeat IS Libs["util/strings"]["str_repeat"].
		IF NOT assertEqual("str_repeat('#',4)",				str_repeat("#",4),				"####")			RETURN FALSE.
		IF NOT assertEqual("str_repeat('#',0)",				str_repeat("#",0),				"")				RETURN FALSE.
		IF NOT assertEqual("str_repeat('#',-1)",			str_repeat("#",-1),				"")				RETURN FALSE.

		RETURN TRUE.
	}

	// LOCAL STR_PAD_LEFT IS -1.
	// LOCAL STR_PAD_BOTH IS 0.
	// LOCAL STR_PAD_RIGHT IS 1.
	// str_pad PARAMETER value, pad_length, pad_string IS " ", pad_direction IS STR_PAD_RIGHT.
	FUNCTION test_str_pad {
		LOCAL str_pad IS Libs["util/strings"]["str_pad"].
		IF NOT assertEqual("str_pad('foobar',6)",			str_pad("foobar",6),			"foobar")		RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',0)",			str_pad("foobar",0),			"foobar")		RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',-1)",			str_pad("foobar",-1),			"foobar")		RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',10)",			str_pad("foobar",10),			"foobar    ")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',10,'#')",		str_pad("foobar",10,"#"),		"foobar####")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',10,'#',1)",	str_pad("foobar",10,"#",1),		"foobar####")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',10,'#',-1)",	str_pad("foobar",10,"#",-1),	"####foobar")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',10,'#',0)",	str_pad("foobar",10,"#",0),		"##foobar##")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',9,'#',0)",		str_pad("foobar",9,"#",0),		"#foobar##")	RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',0,'#',0)",		str_pad("foobar",0,"#",0),		"foobar")		RETURN FALSE.
		IF NOT assertEqual("str_pad('foobar',-9,'#',0)",	str_pad("foobar",-9,"#",0),		"foobar")		RETURN FALSE.

		RETURN TRUE.
	}

	//vsprintf PARAMETER format, args.
	FUNCTION test_vsprintf {
		LOCAL vsprintf IS Libs["util/strings"]["vsprintf"].
		LOCAL testList IS List("A","B","C","D").
		LOCAL testMap IS Lex("A","alpha","B","beta","C","charlie","D","delta").
		LOCAL greekLetters IS Lex("alpha","α","beta","β","gamma","γ","delta","δ","epsilon","ε","mu","μ","pi","π","phi","φ","omega","ω").

		KnuPanic("need to test integer values in map").

		IF NOT assertEqual("vsprintf('sample',testList)",
				vsprintf("sample",testList),
				"sample")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{sample}',testList)",
				vsprintf("{sample}",testList),
				"{sample}")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{s}{a}{m}{p}{l}{e}',testList)",
				vsprintf("{s}{a}{m}{p}{l}{e}",testList),
				"{s}{a}{m}{p}{l}{e}")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{s}{0}{a}{1}{m}{2}{p}{3}{l}{4}{e}',testList)",
				vsprintf("{s}{0}{a}{1}{m}{2}{p}{3}{l}{4}{e}",testList),
				"{s}A{a}B{m}C{p}D{l}{4}{e}")
				RETURN FALSE.

		IF NOT assertEqual("vsprintf('sample',testMap)",
				vsprintf("sample",testMap),
				"sample")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{sample}',testMap)",
				vsprintf("{sample}",testMap),
				"{sample}")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{s}{a}{m}{p}{l}{e}',testMap)",
				vsprintf("{s}{a}{m}{p}{l}{e}",testMap),
				"{s}alpha{m}{p}{l}{e}")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{s}{0}{a}{1}{m}{2}{p}{3}{l}{4}{e}',testMap)",
				vsprintf("{s}{0}{a}{1}{m}{2}{p}{3}{l}{4}{e}",testMap),
				"{s}{0}alpha{1}{m}{2}{p}{3}{l}{4}{e}")
				RETURN FALSE.
		IF NOT assertEqual("vsprintf('{s}{A}{a}{B}{m}{C}{p}{D}{l}{4}{e}',testMap)",
				vsprintf("{s}{A}{a}{B}{m}{C}{p}{D}{l}{4}{e}",testMap),
				"{s}alphaalphabeta{m}charlie{p}delta{l}{4}{e}")
				RETURN FALSE.

		IF NOT assertEqual("vsprintf('{0}{1}{0}{2}{0}{3}{0}{4}{3}{2}{1}{0}',testList)",
				vsprintf("{0}{1}{0}{2}{0}{3}{0}{4}{3}{2}{1}{0}",testList),
				"ABACADA{4}DCBA")
				RETURN FALSE.

		IF NOT assertEqual("vsprintf('{alpha} and {beta} are important, {delta} changes things, we all love {pi} but don't confuse it with {phi}. {omega} is important',greekLetters)",
				vsprintf("{alpha} and {beta} are important, {delta} changes things, we all love {pi} but don't confuse it with {phi}. {omega} is important",greekLetters),
				"α and β are important, δ changes things, we all love π but don't confuse it with φ. ω is important")
				RETURN FALSE.

		RETURN TRUE.
	}

	SET RunTests TO {
		IF NOT test_substr() RETURN FALSE.
		IF NOT test_ltrim() RETURN FALSE.
		IF NOT test_rtrim() RETURN FALSE.
		IF NOT test_trim() RETURN FALSE.
		IF NOT test_str_repeat() RETURN FALSE.
		IF NOT test_str_pad() RETURN FALSE.
		IF NOT test_vsprintf() RETURN FALSE.

		RETURN TRUE.
	}.
}