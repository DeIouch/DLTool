//  查看是否开启权限


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <EventKit/EventKit.h>
#import <CoreTelephony/CTCellularData.h>
#import <HealthKit/HealthKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <PassKit/PassKit.h>
#import <Speech/Speech.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Intents/Intents.h>


typedef NS_ENUM(NSInteger, DLAuthorityType) {
    DLLocationAuthority      =   1, //  定位权限
    DLPushNotiAuthority,            //  是否允许消息推送
    DLCameraAuthority,              //  是否开启摄像头
    DLPhotoAlbumAuthority,          //  是否开启相册
    DLMicrophoneAuthority,          //  是否开启麦克风
    DLAddressBookAuthority,         //  是否开启通讯录
    DLBluetoothAuthority,           //  是否开启蓝牙
    DLCalendarAuthority,            //  是否开启日历
    DLMemorandumAuthority,          //  是否开启备忘录
    DLNetworkingAuthority,          //  是否允许联网
    DLHealthkitAuthority,           //  是否开启健康
    DLTouchIDAuthority,             //  是否开启touchID
    DLApplePayAuthority,            //  是否开启Apple Pay
    DLVoiceOpenAuthority,           //  是否开启语音识别
    DLMediaMusicAuthority,          //  是否开启媒体库/Apple Music
    DLSiriOpenAuthority,            //  是否开启siri
};

typedef NS_ENUM(NSInteger, DLAuthorityOpenType) {
    DLAuthorityAgree   =   0,       //  用户已经同意
    DLAuthorityApply,               //  需要申请
    DLAuthorityNoAuthority,         //  权限收到限制，可能是家长控制权限
    DLAuthorityRefuse,              //  用户已经拒绝
};

@interface DLAuthority : NSObject

//  查看是否已经获取权限
+(DLAuthorityOpenType)authorityIsOpen:(DLAuthorityType)authorityType;

+(BOOL)getAuthority:(DLAuthorityType)authorityType;

@end

/*
 
<!-- 相册 -->
NSPhotoLibraryUsageDescription
App需要您的同意,才能访问相册
 
 
<!-- 相机 -->
NSCameraUsageDescription
App需要您的同意,才能访问相机
 
<!-- 麦克风 -->
NSMicrophoneUsageDescription
App需要您的同意,才能访问麦克风
 
<!-- 位置 -->
NSLocationUsageDescription
App需要您的同意,才能访问位置
 
<!-- 在使用期间访问位置 -->
NSLocationWhenInUseUsageDescription
App需要您的同意,才能在使用期间访问位置
 
<!-- 始终访问位置 -->
NSLocationAlwaysUsageDescription
App需要您的同意,才能始终访问位置
 
<!-- 日历 -->
NSCalendarsUsageDescription
App需要您的同意,才能访问日历
 
<!-- 提醒事项 -->
NSRemindersUsageDescription
App需要您的同意,才能访问提醒事项
 
<!-- 运动与健身 -->
NSMotionUsageDescription
 App需要您的同意,才能访问运动与健身
 
<!-- 健康更新 -->
NSHealthUpdateUsageDescription
App需要您的同意,才能访问健康更新
 
<!-- 健康分享 -->
NSHealthShareUsageDescription
App需要您的同意,才能访问健康分享
 
<!-- 蓝牙 -->
NSBluetoothPeripheralUsageDescription
App需要您的同意,才能访问蓝牙
 
<!-- 媒体资料库 -->
NSAppleMusicUsageDescription
App需要您的同意,才能访问媒体资料库
 
<!-- 语音识别 -->
NSSpeechRecognitionUsageDescription
App需要您的同意,才能使用语音识别

*/
