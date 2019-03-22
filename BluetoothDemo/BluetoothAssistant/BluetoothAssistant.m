//
//  BluetoothAssistant.m
//  BluetoothDemo
//
//  Created by kevin on 2019/3/19.
//  Copyright © 2019 kevin. All rights reserved.
//

#import "BluetoothAssistant.h"

@interface BluetoothAssistant () <CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 代理
 */
@property (nonatomic, weak) id<BluetoothProtocol> Protocol;
/**
 中心管理器
 */
@property (nonatomic, strong) CBCentralManager *manager;
/**
 设备蓝牙状态
 */
@property (nonatomic, assign) CBManagerState managerState;
/**
 设备集合
 */
@property (nonatomic, strong) NSMutableArray *peripherals;
/**
 设备信息
 */
@property (nonatomic, strong) NSMutableArray *peripheralInfos;
/**
 选中的设备
 */
@property (nonatomic, strong) CBPeripheral *peripheral;
/**
 写入标记
 */
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
/**
 接收标记
 */
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;

@end

static NSString *const WriteUUID = @"B0A1A2A3-A4A5-A6A7-A8A9-AAABACADAEAF";
static NSString *const NotifyUUID = @"B1A1A2A3-A4A5-A6A7-A8A9-AAABACADAEAF";
static BluetoothAssistant *_instance;
@implementation BluetoothAssistant

/**
 初始化
 */
+ (BluetoothAssistant *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

/**
 搜索蓝牙
 */
+ (void)scanForPeripherals{
    BluetoothAssistant *bluetooth = [BluetoothAssistant shareInstance];
    [bluetooth.manager stopScan];
    [bluetooth.peripherals removeAllObjects];
    [bluetooth.peripheralInfos removeAllObjects];
    if (bluetooth.managerState == CBManagerStatePoweredOn) {
        NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerScanOptionAllowDuplicatesKey,nil];
        [bluetooth.manager scanForPeripheralsWithServices:nil options:option];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([bluetooth.Protocol respondsToSelector:@selector(bluetooth:List:)]) {
            [bluetooth.Protocol bluetooth:SEARCHEND List:bluetooth.peripheralInfos];
        }
    });
}
/**
 设置代理
 */
+ (void)setProtocol:(id<BluetoothProtocol> __nullable)protocol{
    [BluetoothAssistant shareInstance].Protocol = protocol;
}
/**
 选择连接蓝牙
 */
+ (void)connectPeripheral:(NSString *)identity{
    BluetoothAssistant *bluetooth = [BluetoothAssistant shareInstance];
    [bluetooth.manager stopScan];
    for (CBPeripheral *peripheral in bluetooth.peripherals) {
        if ([peripheral.identifier.UUIDString isEqualToString:identity]) {
            [bluetooth.manager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES, CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES, CBConnectPeripheralOptionNotifyOnNotificationKey: @YES}];
            if ([bluetooth.Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
                [bluetooth.Protocol bluetooth:CONNECTNONE Data:nil];
            }
        }
    }
}
/**
 发送数据
 */
+ (void)postMessage:(Byte[])byte Count:(NSInteger)count{
    BluetoothAssistant *bluetooth = [BluetoothAssistant shareInstance];
    NSData *data = [NSData dataWithBytes:byte length:count];
    if (bluetooth.peripheral && bluetooth.writeCharacteristic) {
        [bluetooth.peripheral writeValue:data forCharacteristic:bluetooth.writeCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}


#pragma mark CBCentralManagerDelegate
/**
 检查蓝牙
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    self.managerState = central.state;
    if ([_Protocol respondsToSelector:@selector(updateState:)]) {
        [_Protocol updateState:central.state];
    }
    switch (central.state) {
        case CBManagerStateUnknown:{
            NSLog(@"未知状态");
        }
            break;
        case CBManagerStateResetting:{
            NSLog(@"重置状态");
        }
            break;
        case CBManagerStateUnsupported:{
            NSLog(@"不支持的状态");
        }
            break;
        case CBManagerStateUnauthorized:{
            NSLog(@"未授权的状态");
        }
            break;
        case CBManagerStatePoweredOff:{
            NSLog(@"关闭状态");
        }
            break;
        case CBManagerStatePoweredOn:{
            NSLog(@"开启状态－可用状态");
            NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerScanOptionAllowDuplicatesKey,nil];
            [central scanForPeripheralsWithServices:nil options:option];
        }
            break;
        default:
            break;
    }
}

/**
 扫描设备
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    if (advertisementData[@"kCBAdvDataManufacturerData"]) {
        if (![self.peripherals containsObject:peripheral]) {
            [self.peripherals addObject:peripheral];
            NSDictionary *info = @{@"identity":peripheral.identifier.UUIDString};
            [self.peripheralInfos addObject:info];
            if ([_Protocol respondsToSelector:@selector(bluetooth:List:)]) {
                [_Protocol bluetooth:SEARCHING List:self.peripheralInfos];
            }
        }
    }
}

/**
 连接断开
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if ([_Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
        [_Protocol bluetooth:DISCONNECT Data:nil];
    }
}

/**
 连接失败
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if ([_Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
        [_Protocol bluetooth:CONNECTFAIL Data:nil];
    }
}

/**
 连接成功
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    self.peripheral = peripheral;
    self.peripheral.delegate = self;
    [peripheral discoverServices:nil];
    if ([_Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
        [_Protocol bluetooth:CONNECTSUCCESS Data:nil];
    }
}

#pragma mark CBPeripheralDelegate
/**
 扫描到服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (self.peripheral != peripheral) {
        return;
    }
    for (int i = 0; i < peripheral.services.count; i ++) {
        CBService *service = peripheral.services[i];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/**
 扫描到对应特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (self.peripheral != peripheral) {
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:WriteUUID]) {
            self.writeCharacteristic = characteristic;
        }else if ([characteristic.UUID.UUIDString isEqualToString:NotifyUUID]) {
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

/**
 根据特征读取数据
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (self.peripheral != peripheral || self.notifyCharacteristic != characteristic) {
        return;
    }
    if ([_Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
        [_Protocol bluetooth:CONNECTSUCCESS Data:characteristic.value];
    }
}

/**
 写入数据成功
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (self.peripheral != peripheral || self.writeCharacteristic != characteristic) {
        return;
    }
    if ([_Protocol respondsToSelector:@selector(bluetooth:Data:)]) {
        [_Protocol bluetooth:CONNECTWRITE Data:characteristic.value];
    }
}

/**
 初始化组件
 */
- (CBCentralManager *)manager{
    if (!_manager) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey, nil];
        _manager = [[CBCentralManager alloc]initWithDelegate:[BluetoothAssistant shareInstance] queue:dispatch_get_main_queue() options:options];
    }
    return _manager;
}

- (NSMutableArray *)peripherals{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (NSMutableArray *)peripheralInfos{
    if (!_peripheralInfos) {
        _peripheralInfos = [NSMutableArray array];
    }
    return _peripheralInfos;
}

@end
