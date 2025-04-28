#define _GNU_SOURCE
#include <locale.h>
#include <sched.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "fs.h"
#include "hash_table.h"

static inline uint64_t rdtsc_start(void)
{
	unsigned hi, lo;
	__asm__ __volatile__("cpuid\n"		  // serializing
			     "rdtsc\n"		  // read TSC
			     : "=a"(lo), "=d"(hi) // output
			     : "a"(0)		  // input: CPUID leaf 0
			     : "rbx", "rcx"	  // clobbered
	);
	return ((uint64_t)hi << 32) | lo;
}

static inline uint64_t rdtsc_end(void)
{
	unsigned hi, lo;
	__asm__ __volatile__("rdtscp\n"
			     "mov %%eax, %0\n"
			     "mov %%edx, %1\n"
			     "cpuid\n"
			     : "=r"(lo), "=r"(hi)
			     :
			     : "rax", "rbx", "rcx", "rdx");
	return ((uint64_t)hi << 32) | lo;
}

const char *TEXT_PATH = "voyna_i_mir.txt";

void run_test(char *text)
{
	hash_table_t table = build_table_from_text(text);

	for (size_t i = 0; i < 50000000; i++)
	{
		table_get_key(&table, "asdasd");
	}

	// table_print_top(&table, 10);

	table_free(&table);
}

int main(int argc, char **argv)
{
	setlocale(LC_CTYPE, "");

	char *text = 0;
	if (!read_file(TEXT_PATH, &text))
	{
		fprintf(stderr, "Unable to read text file!\n");
		return -1;
	}
	//
	// // 2) Pin to CPU 0
	// cpu_set_t cpuset;
	// CPU_ZERO(&cpuset);
	// CPU_SET(4, &cpuset);
	// sched_setaffinity(0, sizeof(cpuset), &cpuset);
	//
	// for(int i = 0; i < 5; i++)
		run_test(text);
	//
	// uint64_t start = rdtsc_start();
	// run_test(text);
	// uint64_t end = rdtsc_end();

	// uint64_t cycles = end - start;
	// printf("Total cycles       : %lu\n", cycles);
	//

	free(text);
	return 0;
}
