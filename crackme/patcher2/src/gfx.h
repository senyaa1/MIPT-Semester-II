#pragma once

#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLTexture>
#include <QOpenGLBuffer>
#include <QOpenGLVertexArrayObject>
#include <QMatrix4x4>
#include <QPainter>
#include <QImage>
#include <QTimerEvent>
#include <QFont>

struct Vertex {
    QVector3D position;
    QVector2D texCoord;
};


class Rotating3DTextWidget : public QOpenGLWidget, protected QOpenGLFunctions
{
private:
    QOpenGLShaderProgram *shaderProgram;
    QOpenGLTexture *texture;
    QOpenGLBuffer vertexBuffer;
    QOpenGLBuffer indexBuffer;
    QOpenGLVertexArrayObject vertexArrayObject;
    QMatrix4x4 projection;
    float angle;
    int timerId;

public:
    Rotating3DTextWidget(QWidget* parent);
    ~Rotating3DTextWidget();

protected:
    void initializeGL() override;
    void resizeGL(int w, int h) override;
    void paintGL() override;
    void timerEvent(QTimerEvent *event) override;
};


