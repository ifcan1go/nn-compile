import torch.nn as nn
import sys
sys.path.append('..')
from function.IOConstraint import IOConstraint



class VGG(nn.Module):
    '''
    modify VGG model for CIFAR-10
    '''
    def __init__(self, iobit=0):
        super(VGG, self).__init__()
        self.classifier = nn.Sequential(
            nn.Linear(128, 500),
            IOConstraint(io_bits=iobit),
            nn.Dropout(p=0.25),
            nn.Linear(500, 10),
        )

        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(32, 32, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(32, 32, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(32, 48, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(48, 48, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Dropout(p=0.25),
            nn.Conv2d(48, 80, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(80, 80, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(80, 80, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(80, 80, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(80, 80, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.MaxPool2d(kernel_size=2, stride=2),
            nn.Dropout(p=0.25),
            nn.Conv2d(80, 128, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(128, 128, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(128, 128, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(128, 128, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.Conv2d(128, 128, kernel_size=3, padding=1),
            IOConstraint(io_bits=iobit),
            nn.MaxPool2d(kernel_size=8, stride=8),
            nn.Dropout(p=0.25),
        )

    def forward(self, x):
        out = self.features(x)
        out = out.view(out.size(0), -1)
        out = self.classifier(out)
        return out
