// blueutil
// Command-line utility to control Bluetooth.
// Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).
// http://www.frederikseiffert.de/blueutil
//
// This software is public domain. It is provided without any warranty
// whatsoever, and may be modified or used without attribution.
//
// Written by Frederik Seiffert <ego@frederikseiffert.de>
//
// Further development by Ivan Kuchin
// https://github.com/toy/blueutil

#define VERSION "2.0.0"

#import <IOBluetooth/IOBluetooth.h>

#include <getopt.h>

// private methods
int IOBluetoothPreferencesAvailable();

int IOBluetoothPreferenceGetControllerPowerState();
void IOBluetoothPreferenceSetControllerPowerState(int state);

int IOBluetoothPreferenceGetDiscoverableState();
void IOBluetoothPreferenceSetDiscoverableState(int state);

// short names
typedef int (*getterFunc)();
typedef bool (*setterFunc)(int);

int BTSetParamState(int state, getterFunc getter, void (*setter)(int), char *name) {
	if (state == getter()) return true;

	setter(state);

	for (int i = 0; i <= 100; i++) {
		if (i) usleep(100000);
		if (state == getter()) return true;
	}

	fprintf(stderr, "Failed to switch bluetooth %s %s in 10 seconds\n", name, state ? "on" : "off");
	return false;
}

#define BTAvaliable IOBluetoothPreferencesAvailable

#define BTPowerState IOBluetoothPreferenceGetControllerPowerState
bool BTSetPowerState(int state) {
	return BTSetParamState(state, BTPowerState, IOBluetoothPreferenceSetControllerPowerState, "power");
}

#define BTDiscoverableState IOBluetoothPreferenceGetDiscoverableState
bool BTSetDiscoverableState(int state) {
	return BTSetParamState(state, BTDiscoverableState, IOBluetoothPreferenceSetDiscoverableState, "discoverable");
}

#define io_puts(io, string) fputs (string"\n", io)

void usage(FILE *io) {
	io_puts(io, "blueutil v"VERSION);
	io_puts(io, "");
	io_puts(io, "Usage:");
	io_puts(io, "  blueutil [options]");
	io_puts(io, "");
	io_puts(io, "Without options outputs current state");
	io_puts(io, "");
	io_puts(io, "    -p, --power                     output power state as 1 or 0");
	io_puts(io, "    -p, --power 1|on|0|off          set power state");
	io_puts(io, "    -d, --discoverable              output discoverable state as 1 or 0");
	io_puts(io, "    -d, --discoverable 1|on|0|off   set discoverable state");
	io_puts(io, "");
	io_puts(io, "    -h, --help                      this help");
	io_puts(io, "    -v, --version                   show version");
}

// getopt_long doesn't consume optional argument separated by space
// https://stackoverflow.com/a/32575314
void extend_optarg(int argc, char *argv[]) {
	if (
		!optarg &&
		optind < argc &&
		NULL != argv[optind] &&
		'-' != argv[optind][0]
	) {
		optarg = argv[optind++];
	}
}

bool parse_state_arg(char *str, int *state) {
	if (
		0 == strcasecmp(str, "1") ||
		0 == strcasecmp(str, "on")
	) {
		if (state) *state = 1;
		return true;
	}

	if (
		0 == strcasecmp(optarg, "0") ||
		0 == strcasecmp(optarg, "off")
	) {
		if (state) *state = 0;
		return true;
	}

	return false;
}

int main(int argc, char *argv[]) {
	if (!BTAvaliable()) {
		io_puts(stderr, "Error: Bluetooth not available!");
		return EXIT_FAILURE;
	}

	if (argc == 1) {
		printf("Power: %d\nDiscoverable: %d\n", BTPowerState(), BTDiscoverableState());
		return EXIT_SUCCESS;
	}

	const char* optstring = "p::d::hv";
	static struct option long_options[] = {
		{"power",           optional_argument, NULL, 'p'},
		{"discoverable",    optional_argument, NULL, 'd'},
		{"help",            no_argument,       NULL, 'h'},
		{"version",         no_argument,       NULL, 'v'},
		{NULL, 0, NULL, 0}
	};

	int ch;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case 'p':
			case 'd':
				extend_optarg(argc, argv);

				if (optarg && !parse_state_arg(optarg, NULL)) {
					fprintf(stderr, "Unexpected value: %s", optarg);
					return EXIT_FAILURE;
				}

				break;
			case 'v':
				io_puts(stdout, VERSION);
				return EXIT_SUCCESS;
			case 'h':
				usage(stdout);
				return EXIT_SUCCESS;
			default:
				usage(stderr);
				return EXIT_FAILURE;
		}
	}

	if (optind < argc) {
		fprintf(stderr, "Unexpected arguments: %s", argv[optind++]);
		while (optind < argc) {
			fprintf(stderr, ", %s", argv[optind++]);
		}
		fprintf(stderr, "\n");
		return EXIT_FAILURE;
	}

	optind = 1;
	while ((ch = getopt_long(argc, argv, optstring, long_options, NULL)) != -1) {
		switch (ch) {
			case 'p':
			case 'd':
				extend_optarg(argc, argv);

				if (optarg) {
					setterFunc setter = ch == 'p' ? BTSetPowerState : BTSetDiscoverableState;

					int state;
					parse_state_arg(optarg, &state);

					if (!setter(state)) {
						return EXIT_FAILURE;
					}
				} else {
					getterFunc getter = ch == 'p' ? BTPowerState : BTDiscoverableState;

					printf("%d\n", getter());
				}

				break;
		}
	}

	return EXIT_SUCCESS;
}
