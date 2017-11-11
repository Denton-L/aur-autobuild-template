FROM archlinux/base

ARG USER_ID=1000
ENV BUILD_USER builder
ENV BUILD_HOME /home/"$BUILD_USER"
ENV BUILD_DIR "$BUILD_HOME"/aur-build

RUN pacman -Syyu --noconfirm --needed base base-devel git

RUN mkdir -p "$BUILD_DIR"
RUN useradd -u "$USER_ID" -s /bin/bash -d "$BUILD_HOME" -G wheel "$BUILD_USER"
RUN chmod -R 777 $BUILD_HOME
RUN chown -R $BUILD_USER $BUILD_HOME
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

VOLUME $BUILD_DIR
WORKDIR $BUILD_DIR
USER $BUILD_USER

CMD ./install.sh
