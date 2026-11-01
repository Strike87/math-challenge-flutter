# Target Clash Arsenal V1 balance contract

Balance Scan consumes its single run use immediately on activation for the current accepting question. Its correct-answer award is the integer floor of half the otherwise earned final question points, after Perfect Hit, Power Shot, Combo and Fever; incorrect and timeout awards remain zero. It expires on resolution or replacement. The player is told this before activation.

Boss Guard consumes its single run use immediately when armed for the current accepting Boss question. Only an incorrect submitted answer preserves the pre-answer Combo; a correct answer, timeout, replacement or phase change expires it. A timeout resets Combo. Wrong answers still score zero, cause no Boss damage and consume a normal Boss attempt. Preserved Combo can increase subsequent multipliers; assisted runs are identified in the transient results and are not comparable to unassisted scores or best combos.

Sign Lens has two uses per run and provides only applicable signed-arithmetic guidance. Triple Memory reads only resolved comparisons in the current Triple phase. Activations and history reset with a new run. No assist pauses the timer. Existing Target Clash record and GameBrain firewalls remain in force; no persistent assist data is added.
