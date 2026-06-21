/**
 * VoiceInputButton — 语音输入按钮组件
 * 长按录音，松手停止并转文字
 */
@Component
export struct VoiceInputButton {
  @Prop isRecording: boolean = false;
  @Prop disabled: boolean = false;
  onStartRecording?: () => void;
  onStopRecording?: () => void;

  build() {
    Column() {
      Button() {
        Row() {
          if (this.isRecording) {
            // 录音中状态
            Text('⏹')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ right: 4 })
            Text('停止录音')
              .fontSize(14)
              .fontColor('#FFFFFF')
          } else {
            SymbolGlyph($r('sys.symbol.mic'))
              .fontSize(16)
              .fontColor(['#FFFFFF'])
              .margin({ right: 4 })
            Text('语音输入')
              .fontSize(14)
              .fontColor('#FFFFFF')
          }
        }
      }
      .type(this.isRecording ? ButtonType.Capsule : ButtonType.Capsule)
      .backgroundColor(this.isRecording ? '#FF3B30' : '#007DFF')
      .borderRadius(20)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .enabled(!this.disabled)
      .opacity(this.disabled ? 0.5 : 1)
      .gesture(
        LongPressGesture({ repeat: false, duration: 300 })
          .onAction(() => {
            if (this.isRecording) {
              this.onStopRecording?.();
            } else {
              this.onStartRecording?.();
            }
          })
      )
      .onClick(() => {
        // 点击切换
        if (this.isRecording) {
          this.onStopRecording?.();
        } else {
          this.onStartRecording?.();
        }
      })

      if (this.isRecording) {
        // 录音波形动画指示
        Row() {
          ForEach([1, 2, 3, 4, 5], (item: number) => {
            Column()
              .width(3)
              .height(12 + Math.random() * 16)
              .borderRadius(2)
              .backgroundColor('#FF3B30')
              .margin({ left: 2, right: 2 })
              .animation({
                duration: 400,
                curve: Curve.EaseInOut,
                iterations: -1,  // 无限循环
                playMode: PlayMode.Alternate
              })
          })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }
    }
    .alignItems(HorizontalAlign.Center)
  }
}
