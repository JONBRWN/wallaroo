import pytest

def pause_for_user():
    """ Asks user to check something manually and answer a question
    """
    notification = "\nPress return to continue.\n"

    # suspend input capture by py.test so user input can be recorded here
    capture_manager = pytest.config.pluginmanager.getplugin('capturemanager')
    capture_manager.suspendcapture(in_=True)

    raw_input(notification)

    # resume capture after question have been asked
    capture_manager.resumecapture()


def test_pause_pytest():
    assert(1)
    pause_for_user()
    assert(1)
