/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the Qt Components project on Qt Labs.
**
** No Commercial Usage
** This file contains pre-release code and may not be distributed.
** You may use this file in accordance with the terms and conditions contained
** in the Technology Preview License Agreement accompanying this package.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** If you have questions regarding the use of this file, please contact
** Nokia at qt-info@nokia.com.
**
****************************************************************************/

import Qt 4.7
import "." 1.0
import "TabGroup.js" as Engine

Item {
    id: root
    property Item currentTab

    property list<Item> contents
    // defect: cannot have list as default property
    default property alias contentsDefault: root.contents

    function addTab(content){
        Engine.addTab(content)
    }

    function removeTab(content){
        Engine.removeTab(content)
    }

    onContentsChanged: {
        Engine.ensureContainers()
    }

    Component {
        id: tabContainerComponent
        Item {
            id: tabContainerItem

            onChildrenChanged: {
                if (children.length == 0)
                    Engine.removeContainer(tabContainerItem)

                else if (children.length == 1) {
                    children[0].width = width
                    children[0].height = height
                    // tab content created. set the first tab as current (if not set before)
                    if (root.currentTab == null)
                        root.currentTab = children[0]
                }
            }

            onWidthChanged: {
                if (children.length > 0)
                    children[0].width = width
            }

            onHeightChanged: {
                if (children.length > 0)
                    children[0].height = height
            }

            Component.onDestruction: {
                if (!root.currentTab) {
                    // selected one deleted. try to activate the neighbour
                    var removedIndex = -1
                    for (var i = 0; i < root.children.length; i++) {
                        if (root.children[i] == tabContainerItem) {
                            removedIndex = i
                            break
                        }
                    }
                    var newIndex = -1
                    if (removedIndex != -1) {
                        if (removedIndex != root.children.length - 1)
                            newIndex = removedIndex + 1
                        else if (removedIndex != 0)
                            newIndex = removedIndex - 1
                    }

                    if (newIndex != -1)
                        root.currentTab = root.children[newIndex].children[0]
                    else
                        root.currentTab = null
                }
            }

            function incomingDone() {
                state = ""
                if (priv.incomingPage) {
                    priv.incomingPage.status = Symbian.PageActive
                    priv.incomingPage = null
                }
            }

            function outgoingDone() {
                state = "Hidden"
                if (priv.outgoingPage) {
                    priv.outgoingPage.status = Symbian.PageInactive
                    priv.outgoingPage.visible = false
                    priv.outgoingPage = null
                }
            }

            width: parent ? parent.width : 0
            height: parent ? parent.height : 0
            state: "Hidden"

            states: [
                State { name: ""; PropertyChanges { target: tabContainerItem; opacity: 1.0 } },
                State { name: "Incoming"; PropertyChanges { target: tabContainerItem; opacity: 1.0 } },
                State { name: "Outgoing"; PropertyChanges { target: tabContainerItem; opacity: 0.0 } },
                State { name: "Hidden"; PropertyChanges { target: tabContainerItem; opacity: 0.0 } }
            ]

            transitions:  [
                Transition {
                    to: "Incoming"
                    SequentialAnimation {
                        PropertyAnimation { properties: "opacity"; easing.type: Easing.OutCubic; duration: 500 }
                        ScriptAction { script: incomingDone() }
                    }
                },
                Transition {
                    to: "Outgoing"
                    SequentialAnimation {
                        PropertyAnimation { properties: "opacity"; easing.type: Easing.OutCubic; duration: 500 }
                        ScriptAction { script: outgoingDone() }
                    }
                }
            ]
        }
    }

    QtObject {
        id: priv
        property bool reparenting: false
        property Item currentTabContainer: root.currentTab ? root.currentTab.parent : null
        property Item incomingPage
        property Item outgoingPage

        onCurrentTabContainerChanged: {
            for (var i = 0; i < root.children.length; i++) {
                var tabContainer = root.children[i]
                var isNewTab = (tabContainer == currentTabContainer)
                if (isNewTab) {
                    if (tabContainer.state != "") {
                        if (tabContainer.children[0].status != undefined) {
                            incomingPage = tabContainer.children[0]
                            incomingPage.status = Symbian.PageActivating
                            incomingPage.visible = true
                            if (incomingPage == outgoingPage)
                                outgoingPage = null
                        }
                        tabContainer.state = "Incoming"
                    }
                } else {
                    if (tabContainer.state != "Hidden") {
                        if (tabContainer.children.length > 0 && tabContainer.children[0].status != undefined) {
                            outgoingPage = tabContainer.children[0]
                            outgoingPage.status = Symbian.PageDeactivating
                            if (incomingPage == outgoingPage)
                                incomingPage = null
                        }
                        tabContainer.state = "Outgoing"
                    }
                }
            }
        }
    }
}