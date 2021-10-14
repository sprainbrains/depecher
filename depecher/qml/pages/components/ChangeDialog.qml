import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: dialog
    property string title
    property string placeHolderText
    property string label
    property string value

    Column {
        width: parent.width
        DialogHeader {
            title: dialog.title
        }

        TextField {
            id: textField
            width: parent.width
            placeholderText: dialog.placeHolderText
            label: dialog.label
            text: dialog.value
        }
    }

    onDone: {
        if (result === DialogResult.Accepted) {
            value = textField.text
        }
    }
}
