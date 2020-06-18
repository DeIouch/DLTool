#import "DLPhotoPick.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface DLPhotoPick()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UIAlertController *alertController;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation DLPhotoPick

static DLPhotoPick *photoPick = nil;

+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        photoPick = [[DLPhotoPick alloc]_init];
    });
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:photoPick.alertController animated:YES completion:nil];
    return photoPick;
}

-(instancetype)_init{
    self = [super init];
    self.alertController = [UIAlertController alertControllerWithTitle:@"" message:@"请选择" preferredStyle:UIAlertControllerStyleActionSheet];
    [self.alertController addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self creatWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [self.alertController addAction:[UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self creatWithSourceType:UIImagePickerControllerSourceTypeCamera];
    }]];
    [self.alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    self.imagePickerController = [[UIImagePickerController alloc]init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = YES;
    return self;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        photoPick = [super allocWithZone:zone];
    });
    return photoPick;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return photoPick;
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone {
    return [self copyWithZone:zone];
}

-(void)creatWithSourceType:(UIImagePickerControllerSourceType)sourceType{
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        }else{
            NSLog(@"设备不支持相机");
            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
    } else {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    UIColor *navBarTintColor  = [UIColor colorWithRed:0.21 green:0.57 blue:0.98 alpha:1.0];
    UIColor *navBarBgColor    = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    UIColor *navBarTitleColor = [UIColor blackColor];
    [self.imagePickerController.navigationBar setBarTintColor:navBarBgColor];
    [self.imagePickerController.navigationBar setTranslucent:NO];
    [self.imagePickerController.navigationBar setTintColor:navBarTintColor];
    [self.imagePickerController.navigationBar setBackgroundColor:navBarBgColor];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSForegroundColorAttributeName] = navBarTitleColor;
    [self.imagePickerController.navigationBar setTitleTextAttributes:attrs];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.imagePickerController animated:YES completion:nil];
}

-(instancetype)allowsEditing:(BOOL)allowsEditing{
    self.imagePickerController.allowsEditing = allowsEditing;
    return self;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{
    if (self.DLPhotoHelperBlock) {
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:( NSString *)kUTTypeImage]) {
            UIImage *image = nil;
            if ([picker allowsEditing]) {
                image = [info objectForKey:UIImagePickerControllerEditedImage];
            } else {
                image = [info objectForKey:UIImagePickerControllerOriginalImage];
            }
            self.DLPhotoHelperBlock(image);
        } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {  // 视频
            NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
            self.DLPhotoHelperBlock(mediaURL);
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
