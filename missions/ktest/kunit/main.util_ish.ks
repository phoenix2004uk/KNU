{
	SET RunTests TO {
		LOCAL IshValue IS Libs["util/ish"]["value"].
		LOCAL IshFactor IS Libs["util/ish"]["factor"].

		IF NOT assertTrue("IshValue(5,5,1)",					IshValue(5,5,1))					RETURN FALSE.
		IF NOT assertTrue("IshValue(5,5,0.5)",					IshValue(5,5,0.5))					RETURN FALSE.
		IF NOT assertTrue("IshValue(5,6,2)",					IshValue(5,6,2))					RETURN FALSE.
		IF NOT assertTrue("IshValue(7,6,2)",					IshValue(7,6,2))					RETURN FALSE.
		IF NOT assertFalse("IshValue(5,6,1)",					IshValue(5,6,1))					RETURN FALSE.
		IF NOT assertFalse("IshValue(7,6,1)",					IshValue(7,6,1))					RETURN FALSE.

		IF NOT assertTrue("IshFactor(9.5,10,0.9)",				IshFactor(9.5,10,0.9))				RETURN FALSE.
		IF NOT assertTrue("IshFactor(10.5,10,0.9)",				IshFactor(10.5,10,0.9))				RETURN FALSE.
		IF NOT assertTrue("IshFactor(9,10,0.8)",				IshFactor(9,10,0.8))				RETURN FALSE.
		IF NOT assertTrue("IshFactor(11,10,0.8)",				IshFactor(11,10,0.8))				RETURN FALSE.
		IF NOT assertFalse("IshFactor(9,10,0.9)",				IshFactor(9,10,0.9))				RETURN FALSE.
		IF NOT assertFalse("IshFactor(11,10,0.9)",				IshFactor(11,10,0.9))				RETURN FALSE.

		RETURN TRUE.
	}.
}