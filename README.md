# nn-compile
nn-compile

本项目展示了针对RRAM特性的神经网络编译的一些关键方法。

其中function目录下IOConstrain.pyt完成IO量子化功能，本项目把它当做一个自定义的激活函数来实现，在建立模型的时候引入该激活函数即可。

function目录下prune.py是剪枝方法，使用pruning生成掩码，使用masking将部分权重强制归零，以实现剪枝操作。

function目录下quantize_weight_noise.py完成了权重量子化以及加入ReRAM器件噪音，可以在训练/推断过程中读取权重值，并按照需要进行量子化以及加入噪音。

model目录下建立了4个NN模型：CIFAR是类似vgg结构的cifar-10分类模型，LeNet是用于MNIST分类的小型CNN模型，mlp是一个用于MNIST的简单的多层感知机，VGG是ImageNet的VGG-16模型。

主目录下给出了MNIST_MLP和CIFAR_VGG两个例子，分别使用mlp和cifar模型。

MNIST——mlp使用了权重/IO量化，加入噪音等技术；

cifar-vgg使用权重/IO量化，加入噪音及剪枝等技术。

为了快速验证cifar-vgg的效果，本项目上传了该模型的权重文件。

上述具体的量子化、噪音等参数均可修改，各个文件内均有参数说明。
