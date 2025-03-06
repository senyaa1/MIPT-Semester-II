#include "gfx.h"

Rotating3DTextWidget::Rotating3DTextWidget(QWidget* parent = nullptr)
    : QOpenGLWidget(parent)
    , shaderProgram(nullptr)
    , texture(nullptr)
    , vertexBuffer(QOpenGLBuffer::VertexBuffer)
    , indexBuffer(QOpenGLBuffer::IndexBuffer)
    , angle(0.0f)
{
    timerId = startTimer(16);
}
Rotating3DTextWidget::~Rotating3DTextWidget()  
{
    makeCurrent();
    vertexArrayObject.destroy();
    vertexBuffer.destroy();
    indexBuffer.destroy();
    delete texture;
    delete shaderProgram;
    doneCurrent();
    killTimer(timerId);
}

void Rotating3DTextWidget::initializeGL() 
{
    initializeOpenGLFunctions();
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.094f, 0.133f, 0.173f, 1.0f);

    // https://learnopengl.com/getting-started/shaders
    shaderProgram = new QOpenGLShaderProgram(this);
    const char *vertexShaderSource =
        "#version 330 core\n"
        "layout(location = 0) in vec3 inPosition;\n"
        "layout(location = 1) in vec2 inTexCoord;\n"
        "uniform mat4 mvpMatrix;\n"
        "out vec2 fragTexCoord;\n"
        "void main() {\n"
        "    gl_Position = mvpMatrix * vec4(inPosition, 1.0);\n"
        "    fragTexCoord = inTexCoord;\n"
        "}\n";
    shaderProgram->addShaderFromSourceCode(QOpenGLShader::Vertex, vertexShaderSource);

    const char *fragmentShaderSource =
        "#version 330 core\n"
        "in vec2 fragTexCoord;\n"
        "out vec4 fragColor;\n"
        "uniform sampler2D textureSampler;\n"
        "void main() {\n"
        "    fragColor = texture(textureSampler, fragTexCoord);\n"
        "}\n";

    shaderProgram->addShaderFromSourceCode(QOpenGLShader::Fragment, fragmentShaderSource);
    shaderProgram->link();

    // QImage textImage(1024, 256, QImage::Format_RGBA8888);
    QImage textImage("resources/ded2.png");
    // textImage.fill(Qt::transparent);
    QPainter painter(&textImage);
    painter.setRenderHint(QPainter::Antialiasing);

    QFont font("Caskaydia Cove Nerd Font", 20, QFont::Bold);
    painter.setFont(font);
    painter.setPen(Qt::red);
    painter.drawText(textImage.rect(), Qt::AlignCenter, "жёсткий патчер");
    painter.end();

    texture = new QOpenGLTexture(textImage);
    texture->setMinificationFilter(QOpenGLTexture::Linear);
    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);

    Vertex vertices[] = {
        { QVector3D(-1.0f, -1.0f, 0.0f), QVector2D(0.0f, 1.0f) },
        { QVector3D( 1.0f, -1.0f, 0.0f), QVector2D(1.0f, 1.0f) },
        { QVector3D( 1.0f,  1.0f, 0.0f), QVector2D(1.0f, 0.0f) },
        { QVector3D(-1.0f,  1.0f, 0.0f), QVector2D(0.0f, 0.0f) }

    };

    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };

    vertexArrayObject.create();
    vertexArrayObject.bind();

    vertexBuffer.create();
    vertexBuffer.bind();
    vertexBuffer.allocate(vertices, 4 * sizeof(Vertex));

    indexBuffer.create();
    indexBuffer.bind();
    indexBuffer.allocate(indices, 6 * sizeof(GLushort));

    shaderProgram->bind();
    vertexBuffer.bind();
    int posLoc = 0;
    int texLoc = 1;
    shaderProgram->enableAttributeArray(posLoc);
    shaderProgram->setAttributeBuffer(posLoc, GL_FLOAT, offsetof(Vertex, position), 3, sizeof(Vertex));
    shaderProgram->enableAttributeArray(texLoc);
    shaderProgram->setAttributeBuffer(texLoc, GL_FLOAT, offsetof(Vertex, texCoord), 2, sizeof(Vertex));
    shaderProgram->release();

    vertexArrayObject.release();
}

void Rotating3DTextWidget::resizeGL(int w, int h)  
{
    glViewport(0, 0, w, h);
    projection.setToIdentity();
    projection.perspective(45.0f, GLfloat(w) / h, 0.1f, 100.0f);
}

void Rotating3DTextWidget::paintGL()  
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    QMatrix4x4 model;
    model.translate(-0.8f, 1.0f, -5.0f);  
    model.rotate(angle, 0.5f, 2.2f, 0.5f);

    QMatrix4x4 mvp = projection * model;

    shaderProgram->bind();
    shaderProgram->setUniformValue("mvpMatrix", mvp);
    shaderProgram->setUniformValue("textureSampler", 0);

    texture->bind(0);

    vertexArrayObject.bind();
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, nullptr);
    vertexArrayObject.release();

    shaderProgram->release();
}

void Rotating3DTextWidget::timerEvent(QTimerEvent *event)  
{
    angle += 1.0f;
    if (angle >= 360.0f)
        angle -= 360.0f;
    update();
}
