import torch.nn as nn
import sys
sys.path.append('..')
from function.IOConstraint import IOConstraint

class LeNet(nn.Module):
    '''
    LeNet model
    '''
    def __init__(self, io_bits=0):
        super(LeNet, self).__init__()
        self.io_bits = io_bits
        self.conv1 = nn.Conv2d(1, 20, 5)
        self.conv2 = nn.Conv2d(20, 50, 5)
        self.fc1 = nn.Linear(50 * 4 * 4, 500)
        self.fc2 = nn.Linear(500, 84)
        self.fc3 = nn.Linear(84, 10)

    def forward(self, x):
        x = x.view(-1, 1, 28, 28)
        out = self.conv1(x)
        out = IOConstraint(io_bits=self.io_bits)(out)
        out = nn.MaxPool2d(2)(out)
        out = self.conv2(out)
        out = IOConstraint(io_bits=self.io_bits)(out)
        out = nn.MaxPool2d(2)(out)
        out = out.view(out.size(0), -1)
        out = self.fc1(out)
        out = IOConstraint(io_bits=self.io_bits)(out)
        out = self.fc2(out)
        out = IOConstraint(io_bits=self.io_bits)(out)
        out = self.fc3(out)
        return out
