TEMPLATE = subdirs
CONFIG += ordered
SUBDIRS = src
tests:SUBDIRS += tests
examples:SUBDIRS += examples

isEmpty(Q_COMPONENTS_SOURCE_TREE)|isEmpty(Q_COMPONENTS_BUILD_TREE) {
    error(Please run configure.)
}
