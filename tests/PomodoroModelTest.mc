using Toybox.Test;
using Toybox.Lang;

(:test)
function testStartSetsRunningWork(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(25, 5, 4, false);
    model.start(preset);
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "State should be RUNNING_WORK");
    Test.assertEqualMessage(1500, model.getRemainingSeconds(), "Remaining should be 25*60=1500");
    Test.assertEqualMessage(1, model.getCurrentCycle(), "Current cycle should be 1");
    Test.assertEqualMessage(0, model.getCyclesCompleted(), "Cycles completed should be 0");
    return true;
}

(:test)
function testTickDecrementsRemaining(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "After 1 tick, remaining should be 1499");
    return true;
}

(:test)
function testTickNoOpWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.tick();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    Test.assertEqualMessage(0, model.getRemainingSeconds(), "Remaining should stay 0");
    return true;
}

(:test)
function testTickNoOpWhenPaused(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.pause();
    var remaining = model.getRemainingSeconds();
    model.tick();
    Test.assertEqualMessage(remaining, model.getRemainingSeconds(), "Remaining should not change while paused");
    return true;
}

(:test)
function testWorkToShortBreakTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    // Simulate all ticks of first work phase
    for (var i = 0; i < 1500; i++) {
        model.tick();
    }
    Test.assertEqualMessage(PomodoroState.RUNNING_SHORT_BREAK, model.getState(), "Should transition to SHORT_BREAK");
    Test.assertEqualMessage(300, model.getRemainingSeconds(), "Short break should be 5*60=300");
    Test.assertEqualMessage(1, model.getCyclesCompleted(), "Cycles completed should be 1");
    return true;
}

(:test)
function testShortBreakToWorkTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    // Complete first work phase
    for (var i = 0; i < 1500; i++) {
        model.tick();
    }
    // Complete short break
    for (var i = 0; i < 300; i++) {
        model.tick();
    }
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should transition back to RUNNING_WORK");
    Test.assertEqualMessage(1500, model.getRemainingSeconds(), "New work phase should be 25*60=1500");
    Test.assertEqualMessage(2, model.getCurrentCycle(), "Current cycle should be 2");
    return true;
}

(:test)
function testLastWorkToLongBreakTransition(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break cycles
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); } // work (1min)
        for (var i = 0; i < 60; i++) { model.tick(); } // short break (1min)
    }
    // Complete 4th (last) work phase
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should transition to LONG_BREAK");
    Test.assertEqualMessage(180, model.getRemainingSeconds(), "Long break should be 1*3*60=180");
    return true;
}

(:test)
function testLongBreakToCompleted(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break + 4th work
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); }
        for (var i = 0; i < 60; i++) { model.tick(); }
    }
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Complete long break (3min)
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");
    return true;
}

(:test)
function testSingleCycleNoLongBreak(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 1, false);
    model.start(preset);
    // Complete the single work phase (1min)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Single cycle should go directly to COMPLETED");
    return true;
}

(:test)
function testPauseAndResume(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick(); // remaining = 1499
    model.pause();
    Test.assertEqualMessage(PomodoroState.PAUSED, model.getState(), "Should be PAUSED");
    Test.assertEqualMessage(true, model.isPaused(), "isPaused should be true");
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should resume to RUNNING_WORK");
    Test.assertEqualMessage(false, model.isPaused(), "isPaused should be false");
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "Remaining should not change during pause");
    return true;
}

(:test)
function testPauseInShortBreakResumesCorrectly(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete first work phase
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Now in short break, pause
    model.pause();
    Test.assertEqualMessage(PomodoroState.PAUSED, model.getState(), "Should be PAUSED");
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_SHORT_BREAK, model.getState(), "Should resume to SHORT_BREAK");
    return true;
}

(:test)
function testPauseInLongBreakResumesCorrectly(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);
    // Complete 3 work + 3 short break + 4th work to get to long break
    for (var cycle = 0; cycle < 3; cycle++) {
        for (var i = 0; i < 60; i++) { model.tick(); }
        for (var i = 0; i < 60; i++) { model.tick(); }
    }
    for (var i = 0; i < 60; i++) { model.tick(); }
    // Now in long break
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should be in LONG_BREAK");
    model.pause();
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should resume to LONG_BREAK");
    return true;
}

(:test)
function testStopResetsEverything(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    model.stop();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should be IDLE after stop");
    Test.assertEqualMessage(0, model.getRemainingSeconds(), "Remaining should be 0");
    Test.assertEqualMessage(0, model.getCurrentCycle(), "Cycle should be 0");
    Test.assertEqualMessage(0, model.getCyclesCompleted(), "CyclesCompleted should be 0");
    Test.assert(model.getPreset() == null);
    return true;
}

(:test)
function testStartIgnoredWhenRunning(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick();
    model.start(new Preset(50, 10, 4, false));
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "Should not restart — remaining stays at 1499");
    return true;
}

(:test)
function testPauseIgnoredWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.pause();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    return true;
}

(:test)
function testResumeIgnoredWhenNotPaused(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.resume();
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "Should remain RUNNING_WORK");
    return true;
}

(:test)
function testStopIgnoredWhenIdle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.stop();
    Test.assertEqualMessage(PomodoroState.IDLE, model.getState(), "Should remain IDLE");
    return true;
}

(:test)
function testObserverReceivesEvents(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    model.addObserver(tracker.method(:onEvent));
    model.start(new Preset(25, 5, 4, false));
    // Should have received ON_START and ON_PHASE_CHANGE
    Test.assertEqualMessage(2, tracker.events.size(), "Should receive 2 events on start");
    Test.assertEqualMessage(PomodoroEvent.ON_START, tracker.events[0], "First event should be ON_START");
    Test.assertEqualMessage(PomodoroEvent.ON_PHASE_CHANGE, tracker.events[1], "Second event should be ON_PHASE_CHANGE");
    return true;
}

(:test)
function testRemoveObserverStopsEvents(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    var cb = tracker.method(:onEvent);
    model.addObserver(cb);
    model.start(new Preset(25, 5, 4, false));
    model.removeObserver(cb);
    model.tick();
    // After remove, should NOT get ON_TICK
    Test.assertEqualMessage(2, tracker.events.size(), "Should still have only 2 events from start");
    return true;
}

(:test)
function testFullCycle25_5_4(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 4, false);
    model.start(preset);

    // Cycle 1: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(1, model.getCyclesCompleted(), "After 1st work: completed=1");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(2, model.getCurrentCycle(), "After 1st break: cycle=2");

    // Cycle 2: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(2, model.getCyclesCompleted(), "After 2nd work: completed=2");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(3, model.getCurrentCycle(), "After 2nd break: cycle=3");

    // Cycle 3: work(60s) + short break(60s)
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(3, model.getCyclesCompleted(), "After 3rd work: completed=3");
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(4, model.getCurrentCycle(), "After 3rd break: cycle=4");

    // Cycle 4 (last): work(60s) -> long break(180s) -> completed
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(4, model.getCyclesCompleted(), "After 4th work: completed=4");
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "Should be in LONG_BREAK");
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");

    return true;
}

(:test)
function testTotalPhaseSecondsUpdates(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    Test.assertEqualMessage(1500, model.getTotalPhaseSeconds(), "Total phase seconds should be 1500 for work");
    // Transition to short break
    for (var i = 0; i < 1500; i++) { model.tick(); }
    Test.assertEqualMessage(300, model.getTotalPhaseSeconds(), "Total phase seconds should be 300 for short break");
    return true;
}

(:test)
function testTickBatchFastCycle(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var preset = new Preset(1, 1, 2, false);
    model.start(preset);
    // Cycle 1: work(60s) + short break(60s)
    for (var i = 0; i < 120; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_WORK, model.getState(), "After cycle 1, should be in WORK again");
    Test.assertEqualMessage(2, model.getCurrentCycle(), "Should be cycle 2");
    // Cycle 2: work(60s) → long break(180s) → completed
    for (var i = 0; i < 60; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.RUNNING_LONG_BREAK, model.getState(), "After cycle 2 work, should be LONG_BREAK");
    for (var i = 0; i < 180; i++) { model.tick(); }
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "After long break, should be COMPLETED");
    return true;
}

(:test)
function testTickBatchDuringPauseIsNoop(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    model.start(new Preset(25, 5, 4, false));
    model.tick(); // remaining = 1499
    model.pause();
    for (var i = 0; i < 100; i++) { model.tick(); }
    Test.assertEqualMessage(1499, model.getRemainingSeconds(), "100 ticks during pause should not change remaining");
    model.resume();
    model.tick();
    Test.assertEqualMessage(1498, model.getRemainingSeconds(), "After resume, tick should decrement again");
    return true;
}

(:test)
function testOnCompleteEventFired(logger as Test.Logger) as Lang.Boolean {
    var model = new PomodoroModel();
    var tracker = new EventTracker();
    model.addObserver(tracker.method(:onEvent));
    var preset = new Preset(1, 1, 1, false);
    model.start(preset);
    // Single cycle: 60 ticks → COMPLETED
    for (var i = 0; i < 60; i++) { model.tick(); }
    var foundComplete = false;
    for (var i = 0; i < tracker.events.size(); i++) {
        if (tracker.events[i] == PomodoroEvent.ON_COMPLETE) {
            foundComplete = true;
        }
    }
    Test.assert(foundComplete);
    Test.assertEqualMessage(PomodoroState.COMPLETED, model.getState(), "Should be COMPLETED");
    return true;
}

// --- Helper class for observer testing ---
class EventTracker {
    var events as Lang.Array<Lang.Number> = [] as Lang.Array<Lang.Number>;

    function initialize() {
    }

    function onEvent(event as Lang.Number) as Void {
        events.add(event);
    }
}
