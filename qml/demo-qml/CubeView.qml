import QtQuick 2.0
import QtGraphicalEffects 1.0
import "CubeView.js" as CubeView
import "Cube.js" as Cube
import "Util.js" as Util

Loader {
    id: loader
    anchors.fill: parent
    sourceComponent: image

    property int currentView
    property real currentIndex
    signal viewUpdateRequest(int prevView, int currView, string image, real newIndex)

    property real brightness: 0
    property real contrast: 0

    property variant topImagesDir
    property variant sideImagesDir
    property variant frontImagesDir

    onCurrentIndexChanged: {
        CubeView._facesData[loader.currentView] = currentIndex
        changeFrontImage(currentIndex)
    }

    Connections {
        target: topImagesDir
        onCountChanged: updateView();
    }
    Connections {
        target: sideImagesDir
        onCountChanged: updateView();
    }
    Connections {
        target: frontImagesDir
        onCountChanged: updateView();
    }

    property url frontImageSrc
    property url leftImageSrc
    property url rightImageSrc
    property url topImageSrc
    property url bottomImageSrc

    property int frontCubeFace: CubeView.FRONT
    property int leftCubeFace: CubeView.SIDE
    property int rightCubeFace: CubeView.SIDE
    property int topCubeFace: CubeView.TOP
    property int bottomCubeFace: CubeView.TOP

    function selectCubeFace(face) {
        loader.sourceComponent = cubeComponent
        loader.item.goToFace(face)
    }

    Component.onCompleted: updateView()

    function updateView() {
        changeFrontImage()
        switch (loader.currentView) {
        case CubeView.TOP:
            leftImageSrc = rightImageSrc = Util.getImgFile(loader.sideImagesDir, CubeView._facesData[CubeView.SIDE])
            bottomImageSrc = topImageSrc = Util.getImgFile(loader.frontImagesDir, CubeView._facesData[CubeView.FRONT])
            frontCubeFace = CubeView.TOP
            leftCubeFace = rightCubeFace = CubeView.SIDE
            bottomCubeFace = topCubeFace = CubeView.FRONT
            break

        case CubeView.SIDE:
            leftImageSrc = rightImageSrc = Util.getImgFile(loader.frontImagesDir, CubeView._facesData[CubeView.FRONT])
            bottomImageSrc = topImageSrc = Util.getImgFile(loader.topImagesDir, CubeView._facesData[CubeView.TOP])
            frontCubeFace = CubeView.SIDE
            leftCubeFace = rightCubeFace = CubeView.FRONT
            bottomCubeFace = topCubeFace = CubeView.TOP
            break

        case CubeView.FRONT:
            leftImageSrc = rightImageSrc = Util.getImgFile(loader.sideImagesDir, CubeView._facesData[CubeView.SIDE])
            bottomImageSrc = topImageSrc = Util.getImgFile(loader.topImagesDir, CubeView._facesData[CubeView.TOP])
            frontCubeFace = CubeView.FRONT
            leftCubeFace = rightCubeFace = CubeView.SIDE
            bottomCubeFace = topCubeFace = CubeView.TOP
            break
        }
    }

    function changeFrontImage(index) {
        var i = index || CubeView._facesData[loader.currentView]
        frontImageSrc = Util.getImgFile(CubeView._imagesData[loader.currentView], i)
    }

    property alias markerModel: markerModel

    function addMarker() {
        var existentMarkers = markerModel.markersInFace(currentView)
        var types = [markerModel.type1, markerModel.type2, markerModel.type3, markerModel.type4]

        var availableTypes = types.slice()
        for (var i = 0; i < existentMarkers.length; i++) {
            var index = availableTypes.indexOf(existentMarkers[i].type)
            if (index != -1)
                availableTypes.splice(index, 1)
        }

        var type
        if (availableTypes.length > 0)
            type = availableTypes[0]
        else {
            console.warn("No available marker colors")
            // Select a random type
            type = types[Math.floor(Math.random() * types.length)]
        }

        // 52 is the size of the marker
        var markerId = markerModel.count + 1
        markerModel.append({"markerId": markerId, "face": loader.currentView, "type": type, "description": "",
                            "x": (loader.width - 52) / 2, "y": (loader.height - 52) / 2})
        return markerId
    }

    property Item _editMarker
    property bool _newMarker: false

    function editMarker(markerId, newMarker) {
        _newMarker = (newMarker === true)

        for (var k = 0; k < loader.item.children.length; k++)
            if (loader.item.children[k].__markerComponent) {
                if (loader.item.children[k].markerId != markerId)
                    loader.item.children[k].opacity = .25
                else {
                    _editMarker = loader.item.children[k]
                    _editMarker.movable = true
                }
            }
    }

    function cancelEditMarker() {
        if (_newMarker) { // if the marker is new,  cancel == delete
            deleteMarker()
            return
        }

        // Restore the item position
        for (var i = 0; i < markerModel.count; i++) {
            var model = markerModel.get(i)
            if (model.markerId == _editMarker.markerId) {
                _editMarker.x = model.x
                _editMarker.y = model.y
            }
        }

        _editMarker.movable = false
        _editMarker = null

        for (var k = 0; k < loader.item.children.length; k++)
            if (loader.item.children[k].__markerComponent)
                loader.item.children[k].opacity = 1
    }

    function confirmEditMarker() {
        for (var i = 0; i < markerModel.count; i++)
            if (markerModel.get(i).markerId == _editMarker.markerId) {
                markerModel.setProperty(i, "x", _editMarker.x)
                markerModel.setProperty(i, "y", _editMarker.y)
            }

        _editMarker.movable = false
        _editMarker = null

        for (var k = 0; k < loader.item.children.length; k++)
            if (loader.item.children[k].__markerComponent)
                loader.item.children[k].opacity = 1
    }

    function deleteMarker() {
        if (!_editMarker)
            return

        for (var i = 0; i < markerModel.count; i++)
            if (markerModel.get(i).markerId == _editMarker.markerId) {
                markerModel.remove(i)
                _editMarker.destroy()
                _editMarker = null
                return
            }
    }

    Component {
        id: markerComponent
        Image {
            property bool __markerComponent: true
            property int markerId: -1
            property bool movable: false

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            MouseArea {
                anchors.fill: parent
                visible: parent.movable
                drag.target: parent
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: loader.width - parent.width
                drag.maximumY: loader.height - parent.height
            }
        }
    }

    MarkerModel {
        id: markerModel

        function createMarkers(faces) {
            for (var i = 0; i < count; i++) {
                var model = get(i)
                var markerProperties = {"markerId": model.markerId, "source": typeToImage(model.type),
                                        "x": model.x, "y": model.y}

                for (var j = 0; j < faces.length; j++)
                    if (model.face == faces[j].face)
                        markerComponent.createObject(faces[j], markerProperties)
            }
        }

        onCountChanged: loader.item.loadMarkers()
    }

    Component {
        id: cubeComponent

        Cube {
            Component.onCompleted: loadMarkers()

            function loadMarkers() {
                var faces = [frontFaceLoader.item, leftFaceLoader.item, rightFaceLoader.item,
                             topFaceLoader.item, bottomFaceLoader.item]

                for (var j = 0; j < faces.length; j++)
                    for (var k = 0; k < faces[j].children.length; k++) {
                        if (faces[j].children[k].__markerComponent) {
                            //console.log("DESTROY ITEM:", faces[j].children[k])
                            faces[j].children[k].destroy()
                        }
                    }

                markerModel.createMarkers(faces)
            }

            frontFaceLoader.sourceComponent: CubeFace {
                source: loader.frontImageSrc
                face: loader.frontCubeFace
            }

            leftFaceLoader.sourceComponent: CubeFace {
                source: loader.leftImageSrc
                face: loader.leftCubeFace
            }

            rightFaceLoader.sourceComponent: CubeFace {
                source: loader.rightImageSrc
                face: loader.rightCubeFace
            }

            topFaceLoader.sourceComponent: CubeFace {
                source: loader.topImageSrc
                face: loader.topCubeFace
            }

            bottomFaceLoader.sourceComponent: CubeFace {
                source: loader.bottomImageSrc
                face: loader.bottomCubeFace
            }

            onFaceSelected: {
                start_gradient.visible = false;
                end_gradient.visible = false;

                var prevView = loader.currentView

                switch (face) {
                case Cube.LEFT:
                case Cube.RIGHT:
                    switch (loader.currentView) {
                    case CubeView.FRONT:
                    case CubeView.TOP:
                        loader.currentView = CubeView.SIDE
                        break

                    case CubeView.SIDE:
                        loader.currentView = CubeView.FRONT
                        break
                    }
                    break

                case Cube.TOP:
                case Cube.BOTTOM:
                    switch (loader.currentView) {
                    case CubeView.TOP:
                        loader.currentView = CubeView.FRONT
                        break

                    case CubeView.FRONT:
                    case CubeView.SIDE:
                        loader.currentView = CubeView.TOP
                        break
                    }
                    break
                }

                // always use the middle image for views on the right of the GUI
                var newImage = Util.getImgFile(CubeView._imagesData[prevView], 0.5)
                var newIndex = CubeView._facesData[loader.currentView]
                updateView()
                loader.viewUpdateRequest(prevView, loader.currentView, newImage, newIndex)
                loader.sourceComponent = image
            }
            onRotationPositionChanged: {
                // params: direction, amount

                // Adjust the amount if negative (movement bottom -> top or right -> left)
                if (rotationPosition < 0) {
                    rotationPosition = loader.width + rotationPosition;
                }
                else if (rotationPosition == 0) {
                    rotationPosition = loader.width;
                }

                // clamp 0 <= value <= 650
                rotationPosition = rotationPosition > loader.width ? loader.width : rotationPosition;
                rotationPosition = rotationPosition < 0 ? 0 : rotationPosition;

                var alpha_end = rotationPosition / loader.width;
                var alpha_start = 1.0 - alpha_end;

                if (rotationDirection === Cube.DIRECTION_X) {
                    start_gradient.visible = true;
                    start_gradient.start = Qt.point(0, 0);
                    start_gradient.end = Qt.point(rotationPosition, 0);
                    start_gradient.gradient.stops[0].color.a = alpha_start;

                    end_gradient.visible = true;
                    end_gradient.start = Qt.point(rotationPosition, 0);
                    end_gradient.end = Qt.point(loader.width, 0);
                    end_gradient.gradient.stops[1].color.a = alpha_end;
                }
                else if (rotationDirection === Cube.DIRECTION_Y) {
                    start_gradient.visible = true;
                    start_gradient.start = Qt.point(0, 0);
                    start_gradient.end = Qt.point(0, rotationPosition);
                    start_gradient.gradient.stops[0].color.a = alpha_start;

                    end_gradient.visible = true;
                    end_gradient.start = Qt.point(0, rotationPosition);
                    end_gradient.end = Qt.point(0, loader.width);
                    end_gradient.gradient.stops[1].color.a = alpha_end;
                }
                else {
                    start_gradient.visible = false;
                    end_gradient.visible = false;
                }
            }
        }
    }

    LinearGradient {
        id: start_gradient
        z: 100
        visible: false
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.50; color: "#b6b7bd" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    LinearGradient {
        id: end_gradient
        z: 100
        visible: false
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.50; color: "#dee0e5" }
        }
    }

    Component {
        id: image

        Image {
            id: staticFace
            property int face: loader.frontCubeFace

            function loadMarkers() {
                for (var k = 0; k < staticFace.children.length; k++)
                    if (staticFace.children[k].__markerComponent) {
                        //console.log("DESTROY ITEM:", staticFace.children[k])
                        staticFace.children[k].destroy()
                    }

                markerModel.createMarkers([staticFace])
            }

            anchors.fill: parent
            source: loader.frontImageSrc
            fillMode: Image.PreserveAspectFit

            BrightnessContrast {
                anchors.fill: parent
                source: parent
                brightness: loader.brightness
                contrast: loader.contrast
            }

            Component.onCompleted: loadMarkers()
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: !loader._editMarker

        onPressed: {
            loader.sourceComponent = cubeComponent
            loader.item.initRotation(mouse)
        }

        onPositionChanged: {
            loader.item.rotate(mouse)
        }

        onReleased: {
            loader.item.finishRotation(mouse)
        }
    }
}
