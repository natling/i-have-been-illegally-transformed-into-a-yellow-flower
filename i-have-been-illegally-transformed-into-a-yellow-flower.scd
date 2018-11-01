(
Buffer.freeAll(s);

z = (
	buffers: ['doors', 'knocks'].collect{
		arg category;
		category -> PathName(thisProcess.nowExecutingPath.dirname +/+ category).files.collect{
			arg file;
			Buffer.read(s, file.fullPath);
		};
	}.asDict(class: Event),

	synthDefs: (
		playBufMono: 1,
		playBufStereo: 2,
	),
);

z.synthDefs.keysValuesDo{
	arg name, numChannels;
	SynthDef(name,
		{
			| out = 0, bufnum = 0, rate = 1, startPos = 0, loop = 0, spread = 0, center = 0, amp = 1 |

			var signal = PlayBuf.ar(
				numChannels: numChannels,
				bufnum: bufnum,
				rate: rate,
				startPos: startPos,
				loop: loop,
				doneAction: 2,
			);

			signal = Splay.ar(inArray: signal, spread: spread, level: amp, center: center);
			Out.ar(out, signal);
		};
	).add;
};

SynthDef(\limiter,
	{
		| bus = 0, level = 1, dur = 0.01 |
		var signal = In.ar(bus: bus, numChannels: 2);
		signal = Limiter.ar(in: signal, level: level, dur: dur);
		ReplaceOut.ar(bus: bus, channelsArray: signal);
	};
).add;
)

(
z.player = Task{
	Synth.tail(defName: \limiter);

	Ptpar([
		0, Ppar(
			z.buffers.knocks.collect{
				arg buffer;
				Pbind(
					\bufnum, buffer,
					\instrument, Pfunc{| thisEvent | z.synthDefs.findKeyForValue(thisEvent.bufnum.numChannels)},
					\rate, Pseg(Pseq([1, 1, 128]), Pseq([1, 7] * 60), 'exp') * Pwhite(0.9, 1.1),
					\delta, Pfunc{| thisEvent | thisEvent.bufnum.duration / thisEvent['rate']},
					\spread, 0,
					\center, Pwhite(-1.0, 1.0),
					\amp, Pwhite(0.5, 1.0),
				);
			};
		),

		8 * 60, Ppar(
			z.buffers.doors.collect{
				arg buffer;
				Pbind(
					\bufnum, buffer,
					\instrument, Pfunc{| thisEvent | z.synthDefs.findKeyForValue(thisEvent.bufnum.numChannels)},
					\rate, Pseg(Pseq([128, 1, 1]), Pseq([7, 1] * 60), 'exp') * Pwhite(0.9, 1.1),
					\delta, Pfunc{| thisEvent | thisEvent.bufnum.duration / thisEvent['rate']},
					\spread, 0,
					\center, Pwhite(-1.0, 1.0),
					\amp, Pwhite(0.5, 1.0),
				);
			};
		),
	]).play;
};

z.recorder = Task{
	s.prepareForRecord;
	2.wait;
	s.record;
	3.wait;
	z.player.play;
	(16 * 60 + 8).wait;
	3.wait;
	s.stopRecording;
};

TempoClock.tempo = 1;
z.player.play;
)