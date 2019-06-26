#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys, pygame 
from pygame import locals
import threading
import time

import random
from pythonosc import udp_client
from pythonosc.osc_message_builder import OscMessageBuilder

import smbus
import argparse
import math

from pythonosc import dispatcher
from pythonosc import osc_server

attitude = {}
servo = {}
pad = {}

attitude['azimuth'] = 0
attitude['pitch'] = 0
attitude['roll'] = 0

done = False
j = None
bus = None

def init_gamepad():
    global done
    pygame.init()
    pygame.joystick.init() # main joystick device system
    done = True

    pad['0'] = 0
    pad['1'] = 0
    pad['2'] = 0
    pad['3'] = 0
    pad['4'] = 0
    pad['5'] = 0
    pad['6'] = 0
    pad['7'] = 0
    pad['8'] = 0
    pad['9'] = 0
    pad['x1'] = 0
    pad['y1'] = 0
    pad['x2'] = 0
    pad['y2'] = 0

    try:
        global j
        j = pygame.joystick.Joystick(0)  # create a joystick instance
        j.init() # init instance
        joyName = j.get_name()
        print("Enabled joystick: " + joyName)
    except pygame.error:
        print("no joystick found.")

def init_i2c():
    global bus
    bus = smbus.SMBus(1)

def init_control():
    servo['pan'] = 0
    servo['tilt'] = 0

def r_motor(duty):
    duty = min([max([duty, -100]), 100])
    duty = duty + 100
    try:
        bus.write_i2c_block_data(0x25, 0x02, [0x01, duty])
    except:
        print("bus restart") 
        init_i2c()

def l_motor(duty):
    duty = min([max([duty, -100]), 100])
    duty = duty+100
    try:
        bus.write_i2c_block_data(0x25, 0x02, [0x02, duty])
    except:
        print("bus restart") 
        init_i2c()

def pan_servo(angle):
    angle = min([max([angle, -90]), 90])
    angle = angle+90
    try:
        bus.write_i2c_block_data(0x25, 0x01, [0x01, angle, 20])
    except:
        print("bus restart") 
        init_i2c()

def tilt_servo(angle):
    angle = min([max([angle, -90]), 90])
    angle = angle+90
    try:
        bus.write_i2c_block_data(0x25, 0x01, [0x02, angle, 20])
    except:
        print("bus restart") 
        init_i2c()

def get_attitude(unused_addr, a, p, r):
    attitude['azimuth'] = int(a)
    attitude['pitch'] = int(p)
    attitude['roll'] = int(r)
    # print(attitude)

def start_osc_server():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="192.168.100.11", help="The ip to listen on")
    parser.add_argument("--port", type=int, default=1222, help="The port to listen on")
    args = parser.parse_args()

    _dispatcher = dispatcher.Dispatcher()
    _dispatcher.map("/a", get_attitude)
   
    server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), _dispatcher)
    print("Serving on {}".format(server.server_address))
    server.serve_forever()

def gamepad_loop():
    global j
    global done
    while done:
        for e in pygame.event.get(): # iterate over event stack
            if e.type == pygame.QUIT:
                done = False
            
            if e.type == pygame.locals.JOYAXISMOTION: # Read Analog Joystick Axis
                x1, y1 = j.get_axis(0)*100, j.get_axis(1)*100  # Left Stick
                x2, y2 = j.get_axis(2)*100, j.get_axis(3)*100  # Right Stick

                pad['x1'] = int(x1)
                pad['y1'] = -int(y1)
                pad['x2'] = int(x2)
                pad['y2'] = -int(y2)
                print(pad)

            if e.type == pygame.locals.JOYBUTTONDOWN: # Read the buttons
                pad[str(e.button)]=1
                print(pad)

            if e.type == pygame.locals.JOYBUTTONUP: # Read the buttons
                pad[str(e.button)]=0
                print(pad)  


def control_loop():
    while True:
        l_motor(pad['y1'])
        r_motor(pad['y2'])
        
        if (- 90 <= attitude['azimuth'] <= 90):
            servo['pan'] = -attitude['azimuth']

        tmp = -attitude['roll']-90
        if (- 90 <= tmp <= 90):
            servo['tilt'] = -tmp

        # print(servo)
        pan_servo(servo['pan'])
        tilt_servo(servo['tilt'])

        time.sleep(0.1)

init_i2c()
init_gamepad()
init_control()

# スレッドに workder1 関数を渡す
t1 = threading.Thread(target=gamepad_loop)
t2 = threading.Thread(target=control_loop)
# スレッドスタート
t1.start()
t2.start()

start_osc_server()
