#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AttributeType) {
    FontSizeAttributeType           =   1,           //  （value是UIFont对象）： 文本大小
    ParagraphStyleAttributeType,                   //  （value是NSParagraphStyle对象） ： 段落风格（设置首行，行间距，对齐方式什么的）
    ForegroundColorAttributeType,                 //  （value是UIColor对象） ： 文本颜色
    BackgroundColorAttributeType,                //  （value是UIColor对象） ： 文本背景色
    LigatureAttributeType,                             //  （value是NSNumber对象）： 设置为文本连体
    KernAttributeType,                                  //  （value是NSNumber对象）： 字符间隔（文字间距）
    StrikethroughStyleAttributeType,               //  （value是NSNumber对象）： 文本添加删除线（单删除线、双删除线）
    UnderlineStyleType,                                 //  （value是NSNumber对象）： 文本设置下划线
    StrokeColorAttributeType,                        //  （value是UIColor对象） ： 设置文本描边颜色
    StrokeWidthAttributeType,                        //  （value是NSNumber对象）：设置描边宽度，和NSStrokeColorAttributeName同时使用能使文字空心
    ShadowAttributeType,                              //  （value是NSShadow对象） ： 设置文本阴影
    TextEffectAttributeType,                           //  （value是NSString） ： 设置文本特殊效果
    AttachmentAttributeType,                         //  （value是NSTextAttachment对象）：设置文本附件，常用于图文混排
    LinkAttributeType,                                   //   （value是NSURL or NSString）：链接
    BaselineOffsetAttributeType,                    //   （value是NSNumber对象）：文字基线偏移
    UnderlineColorAttributeType,                    //   （value是UIColor对象）：下划线颜色
    StrikethroughColorAttributeType,              //    （value是UIColor对象）：删除线颜色
    ObliquenessAttributeType,                        //   （value是NSNumber对象）：设置字体倾斜度
    ExpansionAttributeType,                          //    （value是NSNumber对象）：设置字体的横向拉伸
    WritingDirectionAttributeType,                  //    （value是NSNumber对象）：设置文字书写方向，从左向右书写或者从右向左书写
    VerticalGlyphFormAttributeType,               //    （value是NSNumber对象）：设置文字排版方向
};

@interface NSMutableAttributedString (Add)

+(instancetype)attribute:(NSString *)text type:(AttributeType)type value:(id)value range:(NSRange)range;

@end

