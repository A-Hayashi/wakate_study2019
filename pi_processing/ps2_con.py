#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os, sys, pygame 
from pygame import locals
import time
import signal

import random
from pythonosc import udp_client
from pythonosc.osc_message_builder import OscMessageBuilder

def scheduler(arg1, args2):   
    msg = OscMessageBuilder(address='/c')
    msg.add_arg(arr['y1'])
    msg.add_arg(arr['x1'])
    msg.add_arg(arr['y2'])
    msg.add_arg(arr['x2'])
    m = msg.build()
    
    print(m.address, m.params)
    client.send(m)


IP = '127.0.0.1'
PORT = 1222

pygame.init()
pygame.joystick.init() # main joystick device system
done = True

try:
    j = pygame.joystick.Joystick(0)  # create a joystick instance
    j.init() # init instance
    print("Enabled joystick: " + j.get_name())
    joyName = j.get_name()
except pygame.error:
    print("no joystick found.")

arr = {}
arr['0'] = 0
arr['1'] = 0
arr['2'] = 0
arr['3'] = 0
arr['4'] = 0
arr['5'] = 0
arr['6'] = 0
arr['7'] = 0
arr['8'] = 0
arr['9'] = 0
arr['x1'] = 0
arr['y1'] = 0
arr['x2'] = 0
arr['y2'] = 0

# UDPのクライアントを作る
client = udp_client.UDPClient(IP, PORT)
signal.signal(signal.SIGALRM, scheduler)
signal.setitimer(signal.ITIMER_REAL, 0.1, 0.1)

while done:
    for e in pygame.event.get(): # iterate over event stack
        if e.type == pygame.QUIT:
            done = False
        
        if e.type == pygame.locals.JOYAXISMOTION: # Read Analog Joystick Axis
            x1, y1 = j.get_axis(0)*100, j.get_axis(1)*100  # Left Stick
            x2, y2 = j.get_axis(2)*100, j.get_axis(3)*100  # Right Stick

            arr['x1'] = int(x1)
            arr['y1'] = -int(y1)
            arr['x2'] = int(x2)
            arr['y2'] = -int(y2)
            # print(arr)

        if e.type == pygame.locals.JOYBUTTONDOWN: # Read the buttons
            arr[str(e.button)]=1
            # print(arr)

        if e.type == pygame.locals.JOYBUTTONUP: # Read the buttons
            arr[str(e.button)]=0
            # print(arr)  

