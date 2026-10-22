"""Bounded commands own their inherited process group until output collection ends."""
import os
import signal
import subprocess


def run_owned(command, *, timeout, stdout=None, stderr=None, check=False):
    """Keep subprocess.run's result/errors while stopping descendants on interruption.

    A new session isolates only this invocation and its ordinary descendants.
    Independently detached services are outside that ownership boundary.
    """
    with subprocess.Popen(command, stdout=stdout, stderr=stderr, start_new_session=True) as process:
        try:
            output, errors = process.communicate(timeout=timeout)
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass  # The owned group finished between interruption and cancellation.
            # communicate already attaches partial output to TimeoutExpired.
            # Reap without draining pipes: detached services are not ours to kill
            # and must not keep this timeout waiting for their inherited stdout.
            process.wait()
            raise
        result = subprocess.CompletedProcess(command, process.returncode, output, errors)
        if check:
            result.check_returncode()
        return result
