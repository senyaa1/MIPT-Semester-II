#include <stdio.h>
#include <gtk/gtk.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#include "fs.h"
#include "music.h"

static size_t JNE_OFFSET = 0x28;
static char JNE = 0x75;
static char JE = 0x74;

// password for parol2: "r pEnte"

int patch(const char* filename)
{
	size_t size = 0;
	char* file_buf = read_file(filename, &size);
	if(!file_buf)
	{
		fprintf(stderr, "File not found!\n");
		return 1;
	}

	if(file_buf[JNE_OFFSET] != JNE)	// already patched
	{
		fprintf(stderr, "Already patched!\n");
		return 1;
	}

	file_buf[JNE_OFFSET] = JE;	// invert branch

	printf("Saving!\n");
	write_file(filename, file_buf, size);
	printf("Patched successfully!\n");
	return 0;
}

static void patch_clicked (GtkWidget *widget, gpointer label)
{
	patch(gtk_label_get_text(label));
}

static void on_response(GtkNativeDialog *dialog, gint response, gpointer label) 
{
	if (response == GTK_RESPONSE_ACCEPT)
	{
		g_autoptr (GFile) file = gtk_file_chooser_get_file(GTK_FILE_CHOOSER (dialog));
		char* fileName = g_file_get_path(file);
		gtk_label_set_text(label, fileName);
	}
	gtk_window_destroy(GTK_WINDOW (dialog));

}

static void on_open_clicked(GtkButton *button, gpointer label) 
{
	GtkWindow *parent = GTK_WINDOW(label);

	GtkFileChooserNative *native = gtk_file_chooser_native_new("Open File",
							    parent,
							    GTK_FILE_CHOOSER_ACTION_OPEN,
							    "_Open",
							    "_Cancel");
	g_signal_connect(native, "response", G_CALLBACK(on_response), label);
	gtk_native_dialog_show(GTK_NATIVE_DIALOG(native));
}


static void activate (GtkApplication *app, gpointer user_data)
{
	GtkWidget* window = gtk_application_window_new (app);
	gtk_window_set_title (GTK_WINDOW (window), "Patcher");
	gtk_window_set_default_size (GTK_WINDOW (window), 200, 200);

	GtkWidget *box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
	gtk_widget_set_halign (box, GTK_ALIGN_CENTER);
	gtk_widget_set_valign (box, GTK_ALIGN_CENTER);

	gtk_window_set_child (GTK_WINDOW (window), box);

	GtkWidget *label = gtk_label_new("[File not chosen]");
	gtk_label_set_selectable(GTK_LABEL(label), TRUE);

	GtkWidget *patch_button = gtk_button_new_with_label ("Patch");
	g_signal_connect (patch_button, "clicked", G_CALLBACK (patch_clicked), label);
	g_signal_connect_swapped (patch_button, "clicked", G_CALLBACK (gtk_window_destroy), window);


	GtkWidget *choose_button = gtk_button_new_with_label("Choose a file");
	g_signal_connect (choose_button, "clicked", G_CALLBACK (on_open_clicked), label);


	gtk_box_append (GTK_BOX (box), choose_button);
	gtk_box_append (GTK_BOX (box), label);
	gtk_box_append (GTK_BOX (box), patch_button);

	gtk_window_present (GTK_WINDOW (window));
}


int main(int argc, char** argv)
{
	// pthread_t thread_id = 0;
	// int result = pthread_create(&thread_id, NULL, play_music, NULL);
	// if (result != 0) 
	// {
	// 	fprintf(stderr, "Error creating thread\n");
	// 	return -1;
	// }
	//
	GtkApplication* app = gtk_application_new ("ru.senyaa.patcher", G_APPLICATION_DEFAULT_FLAGS);
	g_signal_connect (app, "activate", G_CALLBACK (activate), NULL);
	int status = g_application_run (G_APPLICATION (app), argc, argv);
	g_object_unref (app);

	return status;
}
