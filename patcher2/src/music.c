#include <unistd.h>
#include <mikmod.h>

static const char* MOD_PATH = "resources/2nd_pm.s3m";

void* play_music(void* vargp)
{
	MikMod_RegisterAllDrivers();
	MikMod_RegisterAllLoaders();

	md_mode |= DMODE_SOFT_MUSIC;
	if (MikMod_Init("")) 
	{
		fprintf(stderr, "Could not initialize sound, reason: %s\n", MikMod_strerror(MikMod_errno));
		return 0;
	}

	MODULE *module = Player_Load(MOD_PATH, 64, 0);

	if (module) 
	{
		Player_Start(module);

		while (Player_Active()) 
		{
			usleep(10000);
			MikMod_Update();
		}

		Player_Stop();
		Player_Free(module);
		return 0;
	} 

	fprintf(stderr, "Could not load module, reason: %s\n", MikMod_strerror(MikMod_errno));
	MikMod_Exit();

	return 0;
}

