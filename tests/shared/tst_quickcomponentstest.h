#include <QDeclarativeComponent>
#include <QDeclarativeEngine>
#include <QDeclarativeView>
#include <QtTest>

// Copied from qt/tests/shared/util.h
// Functions and macros that really need to be in QTestLib
// Will try to wait for the condition while allowing event processing
#define QTRY_VERIFY(__expr) \
    do { \
        const int __step = 50; \
        const int __timeout = 5000; \
        if (!(__expr)) { \
            QTest::qWait(0); \
        } \
        for (int __i = 0; __i < __timeout && !(__expr); __i+=__step) { \
            QTest::qWait(__step); \
        } \
        QVERIFY(__expr); \
    } while(0)

// Will try to wait for the condition while allowing event processing
#define QTRY_COMPARE(__expr, __expected) \
    do { \
        const int __step = 50; \
        const int __timeout = 5000; \
        if ((__expr) != (__expected)) { \
            QTest::qWait(0); \
        } \
        for (int __i = 0; __i < __timeout && ((__expr) != (__expected)); __i+=__step) { \
            QTest::qWait(__step); \
        } \
        QCOMPARE(__expr, __expected); \
    } while(0)

namespace tst_quickcomponentstest
{
    QString errorString(QDeclarativeComponent*);
    QObject* createComponentFromFile(QString const&, QString*,QDeclarativeEngine **engine=0);
    QDeclarativeView *createDeclarativeView(const QString& source);
};

inline
QString tst_quickcomponentstest::errorString(QDeclarativeComponent* component)
{
    QString out;
    if (!component) {
        out = "(null component)";
    }
    else if (component->isError()) {
        QString sep;
        foreach (QDeclarativeError const& e, component->errors()) {
            out += sep + e.toString();
            sep = "\n";
        }
    }

    return out;
}

inline
QObject* tst_quickcomponentstest::createComponentFromFile(QString const& filename, QString* errors, QDeclarativeEngine **engine)
{
    QDeclarativeView *window = new QDeclarativeView;
    if (engine)
        *engine = window->engine();
    window->engine()->addImportPath(Q_COMPONENTS_BUILD_TREE"/imports");
    QDeclarativeComponent *component = new QDeclarativeComponent(window->engine());

    QFile file(filename);
    if (!file.open(QFile::ReadOnly)) {
        if (errors) {
            *errors = QString("Could not open %1: %2").arg(filename).arg(file.errorString());
        }
        return 0;
    }

    component->setData( file.readAll(), QUrl() );

    QObject* out = component->create();
    if (!out) {
        if (errors) {
            *errors = QString("Could not create component from %1: %2").arg(filename).arg(errorString(component));
        }
    }

    return out;
}
inline
QDeclarativeView* tst_quickcomponentstest::createDeclarativeView(const QString& source)
{
    QDeclarativeView* view = new QDeclarativeView(0);
    view->engine()->addImportPath(Q_COMPONENTS_BUILD_TREE"/imports");
    view->setSource(QUrl::fromLocalFile(source));
    view->show();
    QApplication::setActiveWindow(view);
    return view;
}
