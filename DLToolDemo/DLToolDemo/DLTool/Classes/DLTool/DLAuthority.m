#import "DLAuthority.h"

@implementation DLAuthority

+(DLAuthorityOpenType)authorityIsOpen:(DLAuthorityType)authorityType{
    __block DLAuthorityOpenType isOpen = DLAuthorityRefuse;
    switch (authorityType) {
        case DLLocationAuthority:
            {
                switch ([CLLocationManager authorizationStatus]) {
                    case kCLAuthorizationStatusNotDetermined:
                        isOpen = DLAuthorityApply;
                        break;
                    case kCLAuthorizationStatusRestricted:
                        isOpen = DLAuthorityNoAuthority;
                        break;
                    case kCLAuthorizationStatusDenied:
                        isOpen = DLAuthorityRefuse;
                        break;
                    case kCLAuthorizationStatusAuthorizedAlways:
                        isOpen = DLAuthorityAgree;
                        break;
                    case kCLAuthorizationStatusAuthorizedWhenInUse:
                        isOpen = DLAuthorityAgree;
                        break;
                    default:
                        break;
                }
                
            }
            break;
            
        case DLPushNotiAuthority:
            {
                UIUserNotificationSettings *setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
                if (setting.types != UIUserNotificationTypeNone) {
                    isOpen = DLAuthorityAgree;
                }
            }
            break;
            
        case DLCameraAuthority:
            {
                AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                if (authStatus == AVAuthorizationStatusNotDetermined) {
                    isOpen = DLAuthorityApply;
                } else if (authStatus == AVAuthorizationStatusRestricted) {
                    isOpen = DLAuthorityNoAuthority;
                } else if (authStatus == AVAuthorizationStatusDenied) {
                   isOpen = DLAuthorityRefuse;
               }  else {
                    isOpen = DLAuthorityAgree;
                }
            }
            break;
            
        case DLPhotoAlbumAuthority:
            {
                PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
                switch (authStatus) {
                    case PHAuthorizationStatusNotDetermined:
                        {
                            isOpen = DLAuthorityApply;
                        }
                        break;
                        
                    case PHAuthorizationStatusRestricted:
                        {
                            isOpen = DLAuthorityNoAuthority;
                        }
                        break;
                        
                    case PHAuthorizationStatusDenied:
                        {
                            isOpen = DLAuthorityRefuse;
                        }
                        break;
                        
                    case PHAuthorizationStatusAuthorized:
                        {
                            isOpen = DLAuthorityAgree;
                        }
                        break;
                        
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLMicrophoneAuthority:
            {
                AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
                if (permissionStatus == AVAudioSessionRecordPermissionUndetermined) {
//                    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
//                        isOpen = granted;
//                    }];
                    isOpen = DLAuthorityApply;
                } else if (permissionStatus == AVAudioSessionRecordPermissionDenied) {
                    isOpen = DLAuthorityRefuse;
                } else {
                    isOpen = DLAuthorityAgree;
                }
            }
            break;
            
        case DLAddressBookAuthority:
            {
                CNAuthorizationStatus cnAuthStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                switch (cnAuthStatus) {
                    case CNAuthorizationStatusNotDetermined:
                        isOpen = DLAuthorityApply;
                        break;
                        
                        case CNAuthorizationStatusRestricted:
                        isOpen = DLAuthorityNoAuthority;
                        break;
                        
                        case CNAuthorizationStatusDenied:
                        isOpen = DLAuthorityRefuse;
                        break;
                        
                        case CNAuthorizationStatusAuthorized:
                        isOpen = DLAuthorityAgree;
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLBluetoothAuthority:
            {
                CBPeripheralManagerAuthorizationStatus cbAuthStatus = [CBPeripheralManager authorizationStatus];
                switch (cbAuthStatus) {
                    case CBPeripheralManagerAuthorizationStatusNotDetermined:
                        isOpen = DLAuthorityApply;
                        break;
                        
                    case CBPeripheralManagerAuthorizationStatusRestricted:
                        isOpen = DLAuthorityNoAuthority;
                        break;
                    
                    case CBPeripheralManagerAuthorizationStatusDenied:
                        isOpen = DLAuthorityRefuse;
                        break;
                        
                    case CBPeripheralManagerAuthorizationStatusAuthorized:
                        isOpen = DLAuthorityAgree;
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLCalendarAuthority:
            {
                EKAuthorizationStatus ekAuthStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
                
                switch (ekAuthStatus) {
                    case EKAuthorizationStatusNotDetermined:
                        isOpen = DLAuthorityApply;
                        break;
                        
                    case EKAuthorizationStatusRestricted:
                        isOpen = DLAuthorityNoAuthority;
                        break;
                        
                    case EKAuthorizationStatusDenied:
                        isOpen = DLAuthorityRefuse;
                        break;
                        
                    case EKAuthorizationStatusAuthorized:
                        isOpen = DLAuthorityAgree;
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLMemorandumAuthority:
            {
                EKAuthorizationStatus ekAuthStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
                switch (ekAuthStatus) {
                    case EKAuthorizationStatusNotDetermined:
                        isOpen = DLAuthorityApply;
                        break;
                        
                    case EKAuthorizationStatusRestricted:
                        isOpen = DLAuthorityNoAuthority;
                        break;
                        
                    case EKAuthorizationStatusDenied:
                        isOpen = DLAuthorityRefuse;
                        break;
                        
                    case EKAuthorizationStatusAuthorized:
                        isOpen = DLAuthorityAgree;
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLNetworkingAuthority:
            {
                CTCellularData *cellularData = [[CTCellularData alloc] init];
//                cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state){
//                    if (state == kCTCellularDataRestrictedStateUnknown || state == kCTCellularDataNotRestricted) {
//                        isOpen = NO;
//                    } else {
//                        isOpen = YES;
//                    }
//                };
                switch (cellularData.restrictedState) {
                    case kCTCellularDataRestrictedStateUnknown:
                        isOpen = DLAuthorityApply;
                        break;
                        
                    case kCTCellularDataRestricted:
                        isOpen = DLAuthorityRefuse;
                        break;
                        
                    case kCTCellularDataNotRestricted:
                        isOpen = DLAuthorityAgree;
                        break;
                        
                    default:
                        break;
                }
            }
            break;
            
        case DLHealthkitAuthority:
            {
                if (![HKHealthStore isHealthDataAvailable]) {
                    isOpen = DLAuthorityNoAuthority;
                } else {
                    HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                    HKObjectType *hkObjectType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
                    HKAuthorizationStatus hkAuthStatus = [healthStore authorizationStatusForType:hkObjectType];
                    switch (hkAuthStatus) {
                        case HKAuthorizationStatusNotDetermined:
                            isOpen = DLAuthorityApply;
                            break;
                            
                        case HKAuthorizationStatusSharingDenied:
                            isOpen = DLAuthorityRefuse;
                            break;
                            
                        case HKAuthorizationStatusSharingAuthorized:
                            isOpen = DLAuthorityAgree;
                            break;
                            
                        default:
                            break;
                    }
                    
                    
                    
//                    if (hkAuthStatus == HKAuthorizationStatusNotDetermined) {
//                        // 1. 你创建了一个NSSet对象，里面存有本篇教程中你将需要用到的从Health Stroe中读取的所有的类型：个人特征（血液类型、性别、出生日期）、数据采样信息（身体质量、身高）以及锻炼与健身的信息。
////                        NSSet <HKObjectType *> * healthKitTypesToRead = [[NSSet alloc] initWithArray:@[[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType],[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],[HKObjectType workoutType]]];
////                        // 2. 你创建了另一个NSSet对象，里面有你需要向Store写入的信息的所有类型（锻炼与健身的信息、BMI、能量消耗、运动距离）
////                        NSSet <HKSampleType *> * healthKitTypesToWrite = [[NSSet alloc] initWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],[HKObjectType workoutType]]];
////                        [healthStore requestAuthorizationToShareTypes:healthKitTypesToWrite readTypes:healthKitTypesToRead completion:^(BOOL success, NSError *error) {
////                            isOpen = YES;
////                        }];
//
//                        isOpen = NO;
//                    } else if (hkAuthStatus == HKAuthorizationStatusSharingDenied) {
//                        isOpen = NO;
//                    } else {
//                        isOpen = YES;
//                    }
                }
            }
            break;
            
        case DLTouchIDAuthority:
            {
                LAContext *laContext = [[LAContext alloc] init];
                laContext.localizedFallbackTitle = @"输入密码";
                NSError *error;
                if ([laContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
                    isOpen = DLAuthorityAgree;
                    NSLog(@"恭喜,Touch ID可以使用!");
//                        [laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"需要验证您的指纹来确认您的身份信息" reply:^(BOOL success, NSError *error) {
//                            if (success) {
//                                // 识别成功
//                                isOpen = YES;
//                            } else if (error) {
//                                isOpen = NO;
//                                if (error.code == LAErrorAuthenticationFailed) {
//                                    // 验证失败
//                                }
//                                if (error.code == LAErrorUserCancel) {
//                                    // 用户取消
//                                }
//                                if (error.code == LAErrorUserFallback) {
//                                    // 用户选择输入密码
//                                }
//                                if (error.code == LAErrorSystemCancel) {
//                                    // 系统取消
//                                }
//                                if (error.code == LAErrorPasscodeNotSet) {
//                                    // 密码没有设置
//                                }
//                            }
//                        }];
                } else {
                    NSLog(@"设备不支持Touch ID功能,原因:%@",error);
                    isOpen = DLAuthorityRefuse;
                }
            }
            break;
            
        case DLApplePayAuthority:
            {
                NSArray<PKPaymentNetwork> *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkDiscover];
                if ([PKPaymentAuthorizationViewController canMakePayments] && [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
                    isOpen = DLAuthorityAgree;
                } else {
                    isOpen = DLAuthorityRefuse;
                }
            }
            break;
            
        case DLVoiceOpenAuthority:
            {
                if (@available(iOS 10.0, *)) {
                    SFSpeechRecognizerAuthorizationStatus speechAuthStatus = [SFSpeechRecognizer authorizationStatus];
                    switch (speechAuthStatus) {
                        case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                            isOpen = DLAuthorityApply;
                            break;
                            
                        case SFSpeechRecognizerAuthorizationStatusDenied:
                            isOpen = DLAuthorityNoAuthority;
                            break;
                            
                        case SFSpeechRecognizerAuthorizationStatusRestricted:
                            isOpen = DLAuthorityRefuse;
                            break;
                            
                        case SFSpeechRecognizerAuthorizationStatusAuthorized:
                            isOpen = DLAuthorityAgree;
                            break;
                            
                        default:
                            break;
                    }
                } else {
                    isOpen = DLAuthorityRefuse;
                }
            }
            break;
            
        case DLMediaMusicAuthority:
            {
                if (@available(iOS 9.3, *)) {
                    MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
                    switch (authStatus) {
                        case MPMediaLibraryAuthorizationStatusNotDetermined:
                            isOpen = DLAuthorityApply;
                            break;
                            
                        case MPMediaLibraryAuthorizationStatusDenied:
                            isOpen = DLAuthorityNoAuthority;
                            break;
                            
                        case MPMediaLibraryAuthorizationStatusRestricted:
                            isOpen = DLAuthorityRefuse;
                            break;
                            
                        case MPMediaLibraryAuthorizationStatusAuthorized:
                            isOpen = DLAuthorityAgree;
                            break;
                            
                        default:
                            break;
                    }
                } else {
                    isOpen = DLAuthorityRefuse;
                }
            }
            break;
            
        case DLSiriOpenAuthority:
            {
                if (@available(iOS 10.0, *)) {
                    INSiriAuthorizationStatus siriAutoStatus = [INPreferences siriAuthorizationStatus];
                    
                    switch (siriAutoStatus) {
                        case INSiriAuthorizationStatusNotDetermined:
                            isOpen = DLAuthorityApply;
                            break;
                            
                        case INSiriAuthorizationStatusRestricted:
                            isOpen = DLAuthorityNoAuthority;
                            break;
                            
                        case INSiriAuthorizationStatusDenied:
                            isOpen = DLAuthorityRefuse;
                            break;
                            
                        case INSiriAuthorizationStatusAuthorized:
                            isOpen = DLAuthorityAgree;
                            break;
                            
                        default:
                            break;
                    }
                }
            }
            break;
            
        default:
            break;
    }
    return isOpen;
}

+(BOOL)getAuthority:(DLAuthorityType)authorityType{
    __block BOOL isOpen = NO;
    switch (authorityType) {
        case DLLocationAuthority:
            {
                
            }
            break;
            
        case DLPushNotiAuthority:
            {
                UIUserNotificationSettings *requeatSet = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:requeatSet];
                if (requeatSet.types != UIUserNotificationTypeNone) {
                    isOpen = YES;
                }
            }
            break;
            
        case DLCameraAuthority:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    isOpen = granted;
                }];
            }
            break;
            
        case DLPhotoAlbumAuthority:
            {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        isOpen = YES;
                    }
                }];
            }
            break;
            
        case DLMicrophoneAuthority:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                    isOpen = granted;
                }];
            }
            break;
            
        case DLAddressBookAuthority:
            {
                CNContactStore *store = [[CNContactStore alloc] init];
                [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
                    isOpen = granted;
                }];
            }
            break;
            
        case DLBluetoothAuthority:
            {
                
            }
            break;
            
        case DLCalendarAuthority:
            {
                EKEventStore *store = [[EKEventStore alloc] init];
                [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                    isOpen = granted;
                }];
            }
            break;
            
        case DLMemorandumAuthority:
            {
                EKEventStore *store = [[EKEventStore alloc] init];
                [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
                    isOpen = granted;
                }];
            }
            break;
            
        case DLNetworkingAuthority:
            {
                CTCellularData *cellularData = [[CTCellularData alloc] init];
                cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state){
                    if (state == kCTCellularDataRestrictedStateUnknown || state == kCTCellularDataNotRestricted) {
                        isOpen = NO;
                    } else {
                        isOpen = YES;
                    }
                };
            }
            break;
            
        case DLHealthkitAuthority:
            {
                //                        // 1. 你创建了一个NSSet对象，里面存有本篇教程中你将需要用到的从Health Stroe中读取的所有的类型：个人特征（血液类型、性别、出生日期）、数据采样信息（身体质量、身高）以及锻炼与健身的信息。
                HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                NSSet <HKObjectType *> * healthKitTypesToRead = [[NSSet alloc] initWithArray:@[[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType],[HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],[HKObjectType workoutType]]];
                // 2. 你创建了另一个NSSet对象，里面有你需要向Store写入的信息的所有类型（锻炼与健身的信息、BMI、能量消耗、运动距离）
                NSSet <HKSampleType *> * healthKitTypesToWrite = [[NSSet alloc] initWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],[HKObjectType workoutType]]];
                    [healthStore requestAuthorizationToShareTypes:healthKitTypesToWrite readTypes:healthKitTypesToRead completion:^(BOOL success, NSError *error) {
                        isOpen = success;
                    }];
            }
            break;
            
        case DLTouchIDAuthority:
            {
                LAContext *laContext = [[LAContext alloc] init];
                laContext.localizedFallbackTitle = @"输入密码";
                [laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"需要验证您的指纹来确认您的身份信息" reply:^(BOOL success, NSError *error) {
                    if (success) {
                        // 识别成功
                        isOpen = YES;
                    } else if (error) {
                        isOpen = NO;
                        if (error.code == LAErrorAuthenticationFailed) {
                            // 验证失败
                        }
                        if (error.code == LAErrorUserCancel) {
                            // 用户取消
                        }
                        if (error.code == LAErrorUserFallback) {
                            // 用户选择输入密码
                        }
                        if (error.code == LAErrorSystemCancel) {
                            // 系统取消
                        }
                        if (error.code == LAErrorPasscodeNotSet) {
                            // 密码没有设置
                        }
                    }
                }];
            }
            break;
            
        case DLApplePayAuthority:
            {
                
            }
            break;
            
        case DLVoiceOpenAuthority:
            {
                if (@available(iOS 10.0, *)) {
                    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
                        if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = YES;
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = YES;
                            });
                        }
                    }];
                }
            }
            break;
            
        case DLMediaMusicAuthority:
            {
                if (@available(iOS 9.3, *)) {
                    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
                        if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = YES;
                            });
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = NO;
                            });
                        }
                    }];
                }
            }
            break;
            
        case DLSiriOpenAuthority:
            {
                if (@available(iOS 10.0, *)) {
                    [INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
                        if (status == INSiriAuthorizationStatusAuthorized) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = YES;
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                isOpen = YES;
                            });
                        }
                    }];
                }
            }
            break;
            
        default:
            break;
    }
    return isOpen;
}

@end
