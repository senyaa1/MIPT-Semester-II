#include <iostream>
#include <QApplication>
#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <QPushButton>
#include <QStyleFactory>
#include <QFileDialog>
#include <QLineEdit>
#include <QFile>
#include <QLabel>
#include <QWidget>
#include <QUiLoader>
#include <QDebug>
#include <QObject>

#include "gfx.h"
#include "fs.h"

extern "C"
{
    #include "music.h"
    #include "patcher.h"
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QUiLoader loader;
    QFile file("resources/main.ui");

    if (!file.open(QFile::ReadOnly))
    {
        qWarning() << "Cannot open mainwindow.ui:" << file.errorString();
        return -1;
    }

    QWidget *widget = loader.load(&file, nullptr);
    file.close();

    if (!widget)
    {
        qWarning() << "Failed to load UI from file.";
        return -1;
    }

    QFile f("resources/qdarkstyle/dark/darkstyle.qss");

    f.open(QFile::ReadOnly | QFile::Text);
    QTextStream ts(&f);
    qApp->setStyleSheet(ts.readAll());


    pthread_t thread_id = 0;
    int result = pthread_create(&thread_id, NULL, play_music, NULL);
    if (result != 0) 
    {
	fprintf(stderr, "Error creating thread\n");
	return -1;
    }
    
    auto file_path = widget->findChild<QLineEdit*>("file_path");


    auto browse_btn = widget->findChild<QPushButton*>("browse_btn");
    QObject::connect(browse_btn, &QPushButton::clicked, [file_path, widget](){
	QString fileName = QFileDialog::getOpenFileName(
            widget,
            "Open File",
            "",
            "All Files (*)"
	);

        if (!fileName.isEmpty()) 
	    file_path->setText(fileName);
    });

    auto status_label = widget->findChild<QLabel*>("status_label");

    auto patch_btn = widget->findChild<QPushButton*>("patch_btn");
    QObject::connect(patch_btn, &QPushButton::clicked, [status_label, file_path](){
	
	if(patch(file_path->displayText().toStdString().c_str()))
        {
	    status_label->setText("Failure occured during patching! Aborted!");
	    std::cout << "Failure occured !\n";
   	}
	else 
	{
	    status_label->setText("Succesfully patched!");
	}
    });

    auto quit_btn = widget->findChild<QPushButton*>("quit_btn");
    QObject::connect(quit_btn, &QPushButton::clicked, &QApplication::quit);

    auto opengl_widget = widget->findChild<QOpenGLWidget*>("openGLWidget");
    auto gfx = new Rotating3DTextWidget(opengl_widget);

    gfx->resize(800, 600);
    gfx->show();

    widget->show();
    app.exec();

    pthread_cancel(thread_id);
    pthread_join(thread_id, NULL);

    return 0;
}
