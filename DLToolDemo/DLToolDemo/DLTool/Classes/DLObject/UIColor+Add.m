#import "UIColor+Add.h"

@implementation UIColor (Add)

+(UIColor *)ColorWithRed:(CGFloat)red Green:(CGFloat)green Blue:(CGFloat)blue Alpha:(CGFloat)alpha{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

+(UIColor *)ColorWithAHEXColor:(NSString *)apexColor{
    apexColor = [apexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
    switch (apexColor.length) {
        case 3:
            {
                return [[UIColor colorWithRed:strtoul([apexColor substringWithRange:NSMakeRange(0, 1)].UTF8String, 0, 16)/255.0 green:strtoul([apexColor substringWithRange:NSMakeRange(1, 1)].UTF8String, 0, 16)/255.0 blue:strtoul([apexColor substringWithRange:NSMakeRange(2, 1)].UTF8String, 0, 16)/255.0 alpha:1] colorWithAlphaComponent:1];
            }
            break;

        case 4:
            {
                return [[UIColor colorWithRed:strtoul([apexColor substringWithRange:NSMakeRange(0, 1)].UTF8String, 0, 16)/255.0 green:strtoul([apexColor substringWithRange:NSMakeRange(1, 1)].UTF8String, 0, 16)/255.0 blue:strtoul([apexColor substringWithRange:NSMakeRange(2, 1)].UTF8String, 0, 16)/255.0 alpha:strtoul([apexColor substringWithRange:NSMakeRange(3, 1)].UTF8String, 0, 16)/255.0] colorWithAlphaComponent:1];
            }
            break;

        case 6:
            {
                return [[UIColor colorWithRed:strtoul([apexColor substringWithRange:NSMakeRange(0, 2)].UTF8String, 0, 16)/255.0 green:strtoul([apexColor substringWithRange:NSMakeRange(2, 2)].UTF8String, 0, 16)/255.0 blue:strtoul([apexColor substringWithRange:NSMakeRange(4, 2)].UTF8String, 0, 16)/255.0 alpha:1] colorWithAlphaComponent:1];
            }
            break;

        case 8:
            {
                return [[UIColor colorWithRed:strtoul([apexColor substringWithRange:NSMakeRange(0, 2)].UTF8String, 0, 16)/255.0 green:strtoul([apexColor substringWithRange:NSMakeRange(2, 2)].UTF8String, 0, 16)/255.0 blue:strtoul([apexColor substringWithRange:NSMakeRange(4, 2)].UTF8String, 0, 16)/255.0 alpha:strtoul([apexColor substringWithRange:NSMakeRange(6, 2)].UTF8String, 0, 16)/100.0] colorWithAlphaComponent:strtoul([apexColor substringWithRange:NSMakeRange(6, 2)].UTF8String, 0, 16)/100.0];
            }
            break;


        default:
            return [UIColor whiteColor];
            break;
    }
    return [UIColor whiteColor];
}

@end
