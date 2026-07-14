pragma ComponentBehavior: Bound
 
import Quickshell
import QtQuick
import qs.config
import qs.widgets
import QtQuick.Controls

PillBase {
  id: content
  implicitWidth: container.implicitWidth + 20
  implicitHeight: container.implicitHeight + 20

  Column {
    id: container
    anchors.centerIn: parent
    spacing: 4
    Column {
      Text {
        text: "hello"
        color: "#a9b1d6"
        font.pixelSize: 12
      }
    }
    ListView {
      model: Config.settingsKeys
      spacing: 2
      delegate: Row {
        id: rowContainer
        required property string modelData // The name of the property (e.g., "backgroundOpacity")

        Text {
          text: rowContainer.modelData
          color: "#a9b1d6"
          font.pixelSize: 12
        }

        Loader {
            id: controlLoader

            // Pass the setting key down to the loader's scope
            property string settingKey: parent.modelData 

            sourceComponent: {
              let val = Config.adapter[settingKey];
              if (typeof val === "boolean") return checkboxComponent;
              if (typeof val === "number") return sliderComponent;
              return textComponent;
            }
          }
        }
      }
    }
    Component {
      id: sliderComponent
      Slider {
        from: 0.0
        to: 1.0
        value: Config.adapter[parent.settingKey]
        onMoved: {
          Config.adapter[parent.settingKey] = value
        }
      }
    }

    Component {
      id: checkboxComponent
      CheckBox {
        checked: Config.adapter[parent.settingKey]
        onToggled: {
          Config.adapter[parent.settingKey] = checked
        }
      }
    }

    Component {
      id: textComponent
      TextField {
        text: Config.adapter[parent.settingKey]
        onEditingFinished: {
          Config.adapter[parent.settingKey] = text
        }
      }
    }
  }
